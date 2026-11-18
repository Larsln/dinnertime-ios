import Foundation

/// One answer of `GET /sync`: the records that changed or were deleted since a version.
struct SyncChanges {
    /// Number up to which this answer is complete.
    let version: Int
    /// Whether the client has to ask again at once.
    let hasMore: Bool
    /// New and changed records by kind, each in the shape of its detail endpoint.
    let changed: [RecordKind: [JSONObject]]
    /// Ids of deleted records by kind.
    let deleted: [RecordKind: [Int]]
    /// The current settings of the household.
    let household: JSONObject?
    /// The secret by which devices of the household recognise each other.
    let peerKey: String?

    /// Reads the body of the answer; kinds this version does not know are ignored.
    init(data: Data) throws {
        let root = try JSONValue.object(from: data)
        let body = root.value("data", as: JSONObject.self) ?? root
        guard let version = body["version"] as? Int else {
            throw APIError.invalidResponse
        }
        self.version = version
        hasMore = body["has_more"] as? Bool ?? false
        let changedByName = body.value("changed", as: JSONObject.self) ?? [:]
        let deletedByName = body.value("deleted", as: JSONObject.self) ?? [:]
        changed = Dictionary(uniqueKeysWithValues: RecordKind.allCases.map { ($0, changedByName[$0.rawValue] as? [JSONObject] ?? []) })
        deleted = Dictionary(uniqueKeysWithValues: RecordKind.allCases.map { ($0, deletedByName[$0.rawValue] as? [Int] ?? []) })
        household = body.value("household")
        peerKey = body.value("peer_key")
    }
}

/// What a sync run did, for the caller that keeps going or reports progress.
public struct SyncProgress: Equatable, Sendable {
    /// Whether another page has to be fetched at once.
    public let hasMore: Bool
    /// The parts of the app whose data changed.
    public let areas: Set<RealtimeArea>
    /// The secret of the household, to be kept in the Keychain.
    public let peerKey: String?
}

/// Reading of the changes since a version.
public enum SyncEndpoints {
    /// Records per page.
    private static let limit = 200

    /// `GET /sync`: the changes after `version`; the raw answer is handed to the local copy.
    public static func changes(since version: Int) -> Endpoint<Data> {
        let query = [
            URLQueryItem(name: "since", value: String(version)),
            URLQueryItem(name: "limit", value: String(limit)),
        ]
        return Endpoint(.get, "sync", query: query) { $0 }
    }
}
