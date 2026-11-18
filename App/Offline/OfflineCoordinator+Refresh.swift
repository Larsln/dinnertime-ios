import Foundation
import MealplannerKit

/// Bringing the local copy and the server in step: sending the queue, repairs, the feed, waiting links and images.
extension OfflineCoordinator {
    private static let notFoundStatus = 404

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

    /// One pass: queue, repairs, feed, links, images; schedules another when something has to wait.
    func runRefresh(_ credentials: Credentials) async {
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
            try? await repair(client)
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

    func sync(_ client: APIClient) async throws {
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

    func submitLinks(_ client: APIClient) async {
        for link in links.links {
            if (try? await client.send(ImportEndpoints.create(url: link))) != nil {
                links.remove(link)
            }
        }
        pendingLinks = links.links
    }

    /// Downloads the covers that are not stored yet and removes those no recipe refers to any more.
    func fetchImages() async {
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

    /// Reads again what a turned-away change touched: one recipe or product by its detail endpoint, a small kind as a whole.
    ///
    /// A repair that fails stays noted and is tried with the next refresh.
    func repair(_ client: APIClient) async throws {
        for repair in await store.pendingRepairs {
            if let path = repair.detailPath {
                bump(try await store.finish(repair, withRecord: try await record(at: path, client)))
            } else if case let .kind(kind) = repair {
                bump(try await store.finish(repair, withPages: try await pages(of: kind, client)))
            }
        }
    }

    /// The answer of a detail endpoint, or `nil` when the server no longer has the record.
    private func record(at path: String, _ client: APIClient) async throws -> Data? {
        do {
            return try await client.body(of: SyncEndpoints.record(at: path))
        } catch APIError.server(Self.notFoundStatus, _) {
            return nil
        }
    }

    /// All pages of the feed for one kind, read from the start.
    private func pages(of kind: RecordKind, _ client: APIClient) async throws -> [Data] {
        var pages: [Data] = []
        var position = SyncPosition(version: 0, hasMore: true)
        while position.hasMore {
            let page = try await client.body(of: SyncEndpoints.records(of: kind, since: position.version))
            position = try SyncPosition(page: page)
            pages.append(page)
        }
        return pages
    }
}
