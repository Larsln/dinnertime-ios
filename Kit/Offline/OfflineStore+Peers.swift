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
}
