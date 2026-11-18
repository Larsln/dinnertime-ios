import Foundation
import MealplannerKit
import Network
import Observation

/// Keeps the local copy in step with the server and tells the screens what changed.
///
/// All reads and writes of the app pass through here: they are answered from the copy, and
/// writes are queued and sent when the server can be reached. A refresh sends the queue,
/// fetches the changes of the server and downloads missing images.
@MainActor
@Observable
final class OfflineCoordinator {
    /// Paths of read-only answers outside the feed that are kept to be shown without a connection.
    private static let rememberedPaths: Set<String> = ["auth/user", "courses", "imports", "settings/import"]

    /// Whether the last attempt to reach the server worked and the device has a network.
    private(set) var isOnline = true
    /// Number of changes that wait to be sent.
    private(set) var pendingCount = 0
    /// Whether the copy was filled at least once, so that the screens have something to show.
    private(set) var hasSynced = false
    /// Whether the first sync failed for lack of a connection.
    private(set) var firstSyncFailed = false
    /// Counts the completed syncs, for what has to be read again after each.
    private(set) var syncCount = 0
    /// Links that wait for a connection to be imported.
    private(set) var pendingLinks: [URL] = []
    /// What the server refused to save, for an alert.
    var rejectionMessage: String?

    /// Downloaded cover images.
    let images: ImageStore

    private var revisions: [RealtimeArea: Int] = [:]
    private var credentials: Credentials?
    private var isRefreshing = false
    private var wantsAnotherRefresh = false
    private var failures = 0
    private var retry: Task<Void, Never>?
    private var hasNetwork = true
    private var peers: PeerLink?
    private let store: OfflineStore
    private let links = PendingLinks()
    private let peerKeys = PeerKeyStore()
    private let monitor = NWPathMonitor()

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "Offline")) {
        store = OfflineStore(directory: directory.appending(path: "store"))
        images = ImageStore(directory: directory.appending(path: "images"))
    }

    /// How often the data of `area` changed; screens reload when the number of their area grows.
    func revision(of area: RealtimeArea) -> Int {
        revisions[area, default: 0]
    }

    /// Starts working for a signed-in user: reads the state on disk, watches the network and refreshes.
    func start(_ credentials: Credentials) async {
        self.credentials = credentials
        hasSynced = await store.hasSynced
        pendingCount = await store.pendingCount
        pendingLinks = links.links
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.networkChanged(isAvailable: path.status == .satisfied)
            }
        }
        monitor.start(queue: .global(qos: .utility))
        await refresh()
    }

    /// Forgets everything of the signed-in user: the copy, the queue, the images and the secret of the household.
    func wipe() async {
        retry?.cancel()
        stopSharingShoppingList()
        credentials = nil
        await store.wipe()
        images.wipe()
        links.removeAll()
        peerKeys.delete()
        hasSynced = false
        firstSyncFailed = false
        pendingCount = 0
        pendingLinks = []
    }

    /// Answers a call from the copy or applies it there and queues it; `nil` for calls that need the server.
    func answer<Response>(_ endpoint: Endpoint<Response>) async throws -> Response? {
        guard let answer = try await store.answer(endpoint) else {
            return nil
        }
        if let entry = answer.shoppingChange, let change = await store.peerChange(for: entry) {
            peers?.send([change])
        }
        if case let .multipart(form)? = endpoint.body, let entry = await store.pendingChanges.last {
            images.store(form.data, for: entry.pendingCoverAddress)
        }
        if !answer.areas.isEmpty || endpoint.method != .get {
            bump(answer.areas)
            pendingCount = await store.pendingCount
            refreshSoon()
        }
        return answer.response
    }

    /// Takes note that the server answered a call that needed it; a change on the server is fetched at once.
    func serverAnswered<Response>(_ endpoint: Endpoint<Response>, with body: Data) async {
        markReachable()
        if endpoint.method == .get, Self.rememberedPaths.contains(endpoint.path) {
            await store.remember(body, forPath: endpoint.path)
        } else if endpoint.method != .get {
            await refresh()
        }
    }

    /// The answer kept from an earlier call, for reads while the server is known to be away.
    func keptAnswer<Response>(_ endpoint: Endpoint<Response>) async -> Data? {
        guard !isOnline, endpoint.method == .get else {
            return nil
        }
        return await store.rememberedAnswer(forPath: endpoint.path)
    }

    /// Takes note that the server could not be reached and hands out the answer kept from an earlier call, if any.
    func serverUnreachable<Response>(_ endpoint: Endpoint<Response>) async -> Data? {
        markUnreachable()
        return endpoint.method == .get ? await store.rememberedAnswer(forPath: endpoint.path) : nil
    }

    /// Starts exchanging shopping list changes with phones of the household nearby, while the list is on screen.
    ///
    /// The exchange runs whether or not the server can be reached: every change carries its own
    /// key, so one that arrives by both ways is only applied once.
    func startSharingShoppingList() {
        guard peers == nil, let key = peerKeys.load() else {
            return
        }
        let link = PeerLink(peerKey: key) { [weak self] in
            Task { @MainActor in
                await self?.sendQueuedShoppingChanges()
            }
        } onReceive: { [weak self] changes in
            Task { @MainActor in
                await self?.receive(changes)
            }
        }
        peers = link
        link.start()
    }

    /// Ends the exchange with phones nearby.
    func stopSharingShoppingList() {
        peers?.stop()
        peers = nil
    }

    private func sendQueuedShoppingChanges() async {
        peers?.send(await store.shoppingChanges)
    }

    private func receive(_ changes: [PeerChange]) async {
        bump(await store.apply(changes))
        pendingCount = await store.pendingCount
        refreshSoon()
    }

    /// Keeps a link to import it once the server can be reached.
    func keep(_ link: URL) {
        links.add(link)
        pendingLinks = links.links
    }

    /// Refreshes soon without making the caller wait.
    func refreshSoon() {
        Task {
            await refresh()
        }
    }

    /// Sends the queued changes, fetches the changes of the server, submits waiting links and downloads missing images.
    ///
    /// Calls that arrive while a refresh runs are folded into one more run after it.
    func refresh() async {
        guard let credentials else {
            return
        }
        guard !isRefreshing else {
            wantsAnotherRefresh = true
            return
        }
        isRefreshing = true
        repeat {
            wantsAnotherRefresh = false
            await runRefresh(credentials)
        } while wantsAnotherRefresh
        isRefreshing = false
    }

    private func runRefresh(_ credentials: Credentials) async {
        let client = APIClient(serverURL: credentials.serverURL, token: credentials.token)
        let report = await store.drain { entry, upload in
            await client.deliver(entry.urlRequest(serverURL: credentials.serverURL, token: credentials.token, upload: upload))
        }
        pendingCount = await store.pendingCount
        bump(report.areas)
        if let message = report.rejections.first {
            rejectionMessage = message
        }
        do {
            try await sync(client)
            markReachable()
            firstSyncFailed = false
            await submitLinks(client)
            await fetchImages()
        } catch {
            firstSyncFailed = !hasSynced
            if error as? APIError == .unreachable {
                markUnreachable()
            }
        }
        if report.needsRetry || !isOnline {
            scheduleRetry()
        }
    }

    private func sync(_ client: APIClient) async throws {
        var hasMore = true
        while hasMore {
            let page = try await client.body(of: SyncEndpoints.changes(since: await store.syncVersion))
            let progress = try await store.applySync(page)
            hasMore = progress.hasMore
            bump(progress.areas)
            if let key = progress.peerKey, key != peerKeys.load() {
                peerKeys.save(key)
            }
        }
        hasSynced = await store.hasSynced
        syncCount += 1
    }

    private func submitLinks(_ client: APIClient) async {
        for link in links.links {
            if (try? await client.send(ImportEndpoints.create(url: link))) != nil {
                links.remove(link)
            }
        }
        pendingLinks = links.links
    }

    /// Downloads the covers that are not stored yet and removes those no recipe refers to any more.
    private func fetchImages() async {
        let addresses = await store.imageAddresses
        images.prune(keeping: addresses)
        for address in addresses where !images.contains(address) {
            guard let url = URL(string: address), url.scheme != nil, let (data, response) = try? await URLSession.shared.data(from: url) else {
                continue
            }
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                images.store(data, for: address)
            }
        }
    }

    private func networkChanged(isAvailable: Bool) {
        let wasAvailable = hasNetwork
        hasNetwork = isAvailable
        if !isAvailable {
            isOnline = false
        } else if !wasAvailable {
            refreshSoon()
        }
    }

    private func markReachable() {
        failures = 0
        retry?.cancel()
        isOnline = hasNetwork
    }

    private func markUnreachable() {
        isOnline = false
        scheduleRetry()
    }

    /// Tries again after a pause that grows with every failure, as long as something waits or the server is away.
    private func scheduleRetry() {
        guard retry == nil || retry?.isCancelled == true else {
            return
        }
        failures += 1
        let delay = ReconnectBackoff.delay(beforeAttempt: failures)
        retry = Task {
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else {
                return
            }
            retry = nil
            await refresh()
        }
    }

    private func bump(_ areas: Set<RealtimeArea>) {
        for area in areas {
            revisions[area, default: 0] += 1
        }
    }
}
