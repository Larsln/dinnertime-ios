import Foundation

/// The exchange of shopping list changes with devices nearby.
extension OfflineStore {
    /// The queued changes to the shopping list in the form other devices understand, oldest first.
    public var shoppingChanges: [PeerChange] {
        pendingChanges.compactMap(peerChange(for:))
    }

    /// Describes a queued change to the shopping list for other devices; `nil` for other changes.
    public func peerChange(for entry: OutboxEntry) -> PeerChange? {
        guard entry.isShoppingChange else {
            return nil
        }
        let path = entry.path.split(separator: "/").map(String.init)
        let body = entry.body.flatMap { try? JSONValue.object(from: $0) } ?? [:]
        if entry.method == .post, path.count == 3, let listID = Int(path[1]) {
            let item = PeerChange.Item(serverID: nil, creationKey: entry.key)
            return PeerChange(key: entry.key, clientTime: entry.clientTime, item: item, action: .add(label: body["label"] as? String ?? "", listID: listID))
        }
        guard path.count == 2, let id = Int(path[1]) else {
            return nil
        }
        let item = PeerChange.Item(serverID: id > 0 ? id : nil, creationKey: creationKey(ofItem: id))
        if entry.method == .delete {
            return PeerChange(key: entry.key, clientTime: entry.clientTime, item: item, action: .delete)
        }
        guard let checked = body["checked"] as? Bool else {
            return nil
        }
        return PeerChange(key: entry.key, clientTime: entry.clientTime, item: item, action: .check(checked))
    }

    /// Takes over changes another device made.
    ///
    /// A change is applied when it was not seen before and is the later action for its item.
    /// It is then queued under its own key and time, so that this device can deliver it as
    /// well; the server runs it once. Answers with the parts of the app that changed.
    public func apply(_ changes: [PeerChange]) -> Set<RealtimeArea> {
        var areas: Set<RealtimeArea> = []
        for change in changes where !knows(change.key) {
            guard let request = request(for: change), isLater(change), let (result, _) = try? queue(request, key: change.key, at: change.clientTime) else {
                continue
            }
            areas.formUnion(result.areas)
        }
        return areas
    }
}
