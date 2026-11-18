import Foundation

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

    var replica: Replica
    var outbox: [OutboxEntry]
    let replicaFiles: ReplicaFiles
    let outboxFiles: OutboxFiles

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

    /// The version to ask the feed for; zero for a copy that is empty or could not be read.
    public var syncVersion: Int {
        replica.version
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
        let request = try LocalRequest(endpoint).resolving(replica.realIDs)
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
            isShoppingChange: change.shoppingItem != nil,
            repairs: change.repairs
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

    /// Deletes the copy, the queue and the uploads, when the user signs out.
    public func wipe() {
        replicaFiles.wipe()
        outboxFiles.wipe()
        replica = Replica()
        outbox = []
    }

    /// Writes the copy and the queue to disk.
    func save() throws {
        try replicaFiles.save(&replica)
        try outboxFiles.save(outbox)
    }
}
