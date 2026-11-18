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
    var isOnline = true
    /// Number of changes that wait to be sent.
    var pendingCount = 0
    /// Whether the copy was filled at least once, so that the screens have something to show.
    var hasSynced = false
    /// Whether the first sync failed for lack of a connection.
    var firstSyncFailed = false
    /// Counts the completed syncs, for what has to be read again after each.
    var syncCount = 0
    /// Links that wait for a connection to be imported.
    var pendingLinks: [URL] = []
    /// What the server refused to save, for an alert.
    var rejectionMessage: String?

    /// Downloaded cover images.
    let images: ImageStore

    var revisions: [RealtimeArea: Int] = [:]
    var credentials: Credentials?
    var isRefreshing = false
    var wantsAnotherRefresh = false
    var failures = 0
    var retry: Task<Void, Never>?
    var hasNetwork = true
    var peers: PeerLink?
    let store: OfflineStore
    let links = PendingLinks()
    let peerKeys = PeerKeyStore()
    let monitor = NWPathMonitor()

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

    /// Keeps a link to import it once the server can be reached.
    func keep(_ link: URL) {
        links.add(link)
        pendingLinks = links.links
    }

    /// Tells the screens of `areas` that their data changed.
    func bump(_ areas: Set<RealtimeArea>) {
        for area in areas {
            revisions[area, default: 0] += 1
        }
    }
}
