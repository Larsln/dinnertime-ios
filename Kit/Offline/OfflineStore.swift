import Foundation

/// What a run through the queue of changes did.
public struct DrainReport: Equatable, Sendable {
    /// Number of changes the server took over.
    public var delivered = 0
    /// Reasons the server gave for refusing changes.
    public var rejections: [String] = []
    /// Whether changes are left that have to be sent again later.
    public var needsRetry = false
    /// The parts of the app whose data changed while draining.
    public var areas: Set<RealtimeArea> = []
}

/// The offline core of the app: the local copy of the data and the queue of changes that wait for the server.
///
/// Reads are answered from the copy. Writes are applied to it at once and queued; they are
/// sent in order whenever there is a connection. Both are on disk before a call returns.
public actor OfflineStore {
    /// An answer the store gave without the network.
    public struct LocalAnswer<Response: Sendable>: Sendable {
        public let response: Response
        /// The parts of the app whose data the call changed.
        public let areas: Set<RealtimeArea>
        /// The queued change, when the call was a write to the shopping list that devices nearby should learn of.
        public let shoppingChange: OutboxEntry?
    }

    private var replica: Replica
    private var outbox: [OutboxEntry]
    private var fullSyncPages: [SyncChanges] = []
    private let replicaFiles: ReplicaFiles
    private let outboxFiles: OutboxFiles

    /// Opens the store in `directory`, reading what an earlier run left there.
    public init(directory: URL) {
        replicaFiles = ReplicaFiles(directory: directory.appending(path: "replica"))
        outboxFiles = OutboxFiles(directory: directory.appending(path: "outbox"))
        replica = replicaFiles.load()
        outbox = outboxFiles.load()
    }

    /// Whether the copy was filled by a sync at least once.
    public var hasSynced: Bool {
        replica.version > 0
    }

    /// The version to ask the feed for: zero while the whole copy has to be replaced.
    public var syncVersion: Int {
        replica.needsFullSync && fullSyncPages.isEmpty ? 0 : (fullSyncPages.last?.version ?? replica.version)
    }

    /// Number of changes that wait to be sent.
    public var pendingCount: Int {
        outbox.count
    }

    /// The queued changes in the order they are sent.
    public var pendingChanges: [OutboxEntry] {
        outbox
    }

    /// The default servings of the household as last synced.
    public var defaultServings: Int? {
        replica.household["default_servings"] as? Int
    }

    /// Addresses of all cover images the copy refers to, list versions first.
    public var imageAddresses: [String] {
        let recipes = replica.all(.recipes)
        return recipes.compactMap { $0["cover_thumb_url"] as? String } + recipes.compactMap { $0["cover_url"] as? String }
    }

    /// The content of the upload a queued change carries.
    public func upload(forKey key: String) -> Data? {
        try? Data(contentsOf: outboxFiles.uploadFile(forKey: key))
    }

    /// Answers a call from the copy, or applies it to the copy and queues it; `nil` for calls that need the server.
    ///
    /// Throws what the server would answer, for example `404` for a record the copy does not hold.
    public func answer<Response>(_ endpoint: Endpoint<Response>, now: Date = .now) throws -> LocalAnswer<Response>? {
        let request = try LocalRequest(endpoint)
        if let body = try replica.read(request) {
            return LocalAnswer(response: try endpoint.decode(JSONValue.data(body)), areas: [], shoppingChange: nil)
        }
        guard let (result, entry) = try queue(request, key: UUID().uuidString, at: now) else {
            return nil
        }
        let response = try endpoint.decode(JSONValue.data(result.body ?? JSONObject()))
        return LocalAnswer(response: response, areas: result.areas, shoppingChange: entry.isShoppingChange ? entry : nil)
    }

    /// Applies a write to the copy and queues it under `key` as done at `time`; `nil` for calls that need the server.
    func queue(_ request: LocalRequest, key: String, at time: Date) throws -> (LocalResult, OutboxEntry)? {
        guard let result = try replica.write(request, key: key, now: time), let change = result.change else {
            return nil
        }
        var entry = OutboxEntry(
            key: key,
            clientTime: time,
            method: request.method,
            path: request.path.joined(separator: "/"),
            body: request.upload == nil && !request.body.isEmpty ? try JSONValue.data(request.body) : nil,
            upload: nil,
            created: change.created,
            createdKind: change.createdKind,
            isShoppingChange: change.shoppingItem != nil
        )
        if let form = request.upload {
            entry.upload = OutboxEntry.Upload(field: form.field, fileName: form.fileName, mimeType: form.mimeType)
            try FileManager.default.createDirectory(at: outboxFiles.directory, withIntermediateDirectories: true)
            try form.data.write(to: outboxFiles.uploadFile(forKey: key), options: .atomic)
        }
        if entry.isShoppingChange {
            replica.rememberShoppingKey(key)
        }
        outbox.append(entry)
        try save()
        return (result, entry)
    }

    /// Whether a change to the shopping list with `key` was made here or received before.
    func knows(_ key: String) -> Bool {
        replica.knownShoppingKeys.contains(key)
    }

    /// The key of the request that created the shopping item with `id`, if it was created offline.
    func creationKey(ofItem id: Int) -> String? {
        replica.shoppingItem(id)?["creation_key"] as? String ?? replica.itemIDsByCreationKey.first { $0.value == id }?.key
    }

    /// The id under which this device holds the item another device names.
    func itemID(for item: PeerChange.Item) -> Int? {
        if let id = item.serverID, replica.shoppingItem(id) != nil {
            return id
        }
        guard let key = item.creationKey else {
            return nil
        }
        if let id = replica.itemIDsByCreationKey[key], replica.shoppingItem(id) != nil {
            return id
        }
        let items = replica.all(.shoppingLists).flatMap { $0["items"] as? [JSONObject] ?? [] }
        return items.first { $0["creation_key"] as? String == key }?.recordID
    }

    /// The call that repeats the change of another device on this one; `nil` when its item or list is unknown here.
    func request(for change: PeerChange) -> LocalRequest? {
        switch change.action {
        case let .add(label, listID):
            guard itemID(for: change.item) == nil, replica.record(.shoppingLists, listID) != nil else {
                return nil
            }
            return LocalRequest(method: .post, path: "shopping-lists/\(listID)/items", body: ["label": label])
        case let .check(checked):
            return itemID(for: change.item).map { LocalRequest(method: .patch, path: "shopping-list-items/\($0)", body: ["checked": checked]) }
        case .delete:
            return itemID(for: change.item).map { LocalRequest(method: .delete, path: "shopping-list-items/\($0)") }
        }
    }

    /// Whether no action on the item of `change` is known that happened at the same time or later.
    func isLater(_ change: PeerChange) -> Bool {
        guard let id = itemID(for: change.item), let last = replica.itemActionTimes[id] else {
            return true
        }
        return change.clientTime > last
    }

    /// Keeps the answer of a read-only endpoint that is not part of the feed, to show it again without a connection.
    public func remember(_ answer: Data, forPath path: String) {
        guard let value = try? JSONSerialization.jsonObject(with: answer) else {
            return
        }
        replica.cachedAnswers[path] = value
        try? save()
    }

    /// The answer last kept for `path`.
    public func rememberedAnswer(forPath path: String) -> Data? {
        replica.cachedAnswers[path].flatMap { try? JSONValue.data($0) }
    }

    /// Applies one page of the feed.
    ///
    /// While the whole copy is replaced, pages are collected and applied together with the last one.
    public func applySync(_ page: Data) throws -> SyncProgress {
        let changes = try SyncChanges(data: page)
        var areas: Set<RealtimeArea> = []
        if replica.needsFullSync {
            fullSyncPages.append(changes)
            if !changes.hasMore {
                areas = replica.replace(with: fullSyncPages)
                fullSyncPages = []
            }
        } else {
            areas = replica.apply(changes)
        }
        try save()
        return SyncProgress(hasMore: changes.hasMore, areas: areas, peerKey: changes.peerKey)
    }

    /// Sends the queued changes in order until the queue is empty or one has to wait.
    ///
    /// `deliver` sends one change, with the content of its upload, and reports what came back.
    public func drain(using deliver: @Sendable (OutboxEntry, Data?) async -> DeliveryResult) async -> DrainReport {
        var report = DrainReport()
        while let entry = outbox.first {
            let outcome = OutboxOutcome(await deliver(entry, upload(forKey: entry.key)))
            guard outbox.first?.key == entry.key else {
                continue
            }
            switch outcome {
            case .retry:
                report.needsRetry = true
                return report
            case let .delivered(body):
                report.delivered += 1
                report.areas.formUnion(settle(entry, answer: body))
            case .dropped:
                report.areas.formUnion(giveUp(entry))
            case let .rejected(message):
                report.rejections.append(message)
                report.areas.formUnion(giveUp(entry))
            }
            outbox.removeFirst()
            try? FileManager.default.removeItem(at: outboxFiles.uploadFile(forKey: entry.key))
            try? save()
        }
        return report
    }

    /// Deletes the copy, the queue and the uploads, when the user signs out.
    public func wipe() {
        replicaFiles.wipe()
        outboxFiles.wipe()
        replica = Replica()
        outbox = []
        fullSyncPages = []
    }

    /// Takes over the real ids of created records and, where nothing else waits for them, the records themselves.
    private func settle(_ entry: OutboxEntry, answer: Data) -> Set<RealtimeArea> {
        guard !entry.created.isEmpty, let root = try? JSONValue.object(from: answer) else {
            return []
        }
        let answered = (root["data"] as? [JSONObject]) ?? (root["data"] as? JSONObject).map { [$0] } ?? []
        for (temporary, record) in zip(entry.created, answered) {
            guard let real = record.recordID else {
                continue
            }
            replica.replaceID(temporary, with: real)
            let isAwaited = outbox.dropFirst().contains { $0.refers(to: temporary) }
            for index in outbox.indices.dropFirst() {
                outbox[index].replaceID(temporary, with: real)
            }
            if let kind = entry.createdKind, !isAwaited {
                replica.put(kind, (replica.record(kind, real) ?? [:]).merging(record) { _, answered in answered })
            }
            if entry.isShoppingChange {
                replica.itemIDsByCreationKey[entry.key] = real
            }
        }
        return Set(RealtimeArea.allCases)
    }

    /// Removes what a refused change created and makes the next sync restore the state of the server.
    private func giveUp(_ entry: OutboxEntry) -> Set<RealtimeArea> {
        for temporary in entry.created {
            if let kind = entry.createdKind {
                replica.remove(kind, temporary)
            }
        }
        replica.needsFullSync = true
        return Set(RealtimeArea.allCases)
    }

    private func save() throws {
        try replicaFiles.save(&replica)
        try outboxFiles.save(outbox)
    }
}
