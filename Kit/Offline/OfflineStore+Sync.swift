import Foundation

/// Taking over what the server reports: the feed of changes and the repairs after a change was turned away.
extension OfflineStore {
    /// Parts of the copy that have to be read from the server again, oldest first.
    public var pendingRepairs: [RecordRepair] {
        replica.pendingRepairs
    }

    /// Applies one page of the feed and takes over its version.
    public func applySync(_ page: Data) throws -> SyncProgress {
        let changes = try SyncChanges(data: page)
        let areas = replica.apply(changes)
        try save()
        return SyncProgress(hasMore: changes.hasMore, areas: areas, peerKey: changes.peerKey)
    }

    /// Finishes the repair of one record with the answer of its detail endpoint; `nil` when the server no longer has it.
    public func finish(_ repair: RecordRepair, withRecord answer: Data?) throws -> Set<RealtimeArea> {
        guard case let .record(kind, id) = repair else {
            return []
        }
        if let answer {
            guard let record = try JSONValue.object(from: answer)["data"] as? JSONObject else {
                throw APIError.invalidResponse
            }
            replica.put(kind, record)
        } else {
            replica.remove(kind, id)
        }
        return try finished(repair, areas: [kind.area, .plan, .shopping, .pantry])
    }

    /// Finishes the repair of a kind with all pages of a feed that was asked for this kind only.
    ///
    /// The version of these pages is not taken over.
    public func finish(_ repair: RecordRepair, withPages pages: [Data]) throws -> Set<RealtimeArea> {
        guard case let .kind(kind) = repair else {
            return []
        }
        replica.replaceKind(kind, with: try pages.map(SyncChanges.init(data:)))
        return try finished(repair, areas: [kind.area])
    }

    private func finished(_ repair: RecordRepair, areas: Set<RealtimeArea>) throws -> Set<RealtimeArea> {
        replica.pendingRepairs.removeAll { $0 == repair }
        try save()
        return areas
    }
}
