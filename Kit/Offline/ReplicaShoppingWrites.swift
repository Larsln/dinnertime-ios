import Foundation

/// Writes to the shopping list, applied to the local copy.
extension Replica {
    /// Answers a write to a shopping list; `nil` for other calls, among them creating a list, which needs the server.
    mutating func writeShopping(_ request: LocalRequest, key: String, now: Date) throws -> LocalResult? {
        if request.matches(.post, "shopping-lists", "*", "items") {
            return try addShoppingItem(request, key: key, now: now)
        }
        if request.matches(.post, "shopping-lists", "*", "stock-leftovers") {
            var list = try existing(.shoppingLists, request.id(at: 1))
            guard list["leftovers_stocked_at"] is NSNull || list["leftovers_stocked_at"] == nil else {
                throw failure(409)
            }
            list["leftovers_stocked_at"] = JSONValue.timestamp(now)
            put(.shoppingLists, list)
            return LocalResult(body: resource(shownList(list)), areas: [.shopping], change: QueuedChange())
        }
        guard request.path.first == "shopping-list-items", let id = request.id(at: 1), var list = listHolding(item: id) else {
            return request.path.first == "shopping-list-items" ? try missing() : nil
        }
        var items = list["items"] as? [JSONObject] ?? []
        guard let index = items.firstIndex(where: { $0.recordID == id }) else {
            return try missing()
        }
        var answer: Any?
        if request.matches(.patch, "shopping-list-items", "*") {
            if let checked = request.body["checked"] as? Bool {
                items[index]["checked_at"] = checked ? JSONValue.timestamp(now) : NSNull()
            }
            if let label = request.body["label"] {
                items[index]["label"] = label
            }
            answer = resource(shownItem(items[index]))
        } else if request.matches(.delete, "shopping-list-items", "*") {
            items.remove(at: index)
        } else {
            return nil
        }
        list["items"] = items
        put(.shoppingLists, list)
        itemActionTimes[id] = now
        return LocalResult(body: answer, areas: [.shopping], change: QueuedChange(shoppingItem: id))
    }

    /// Adds a manual item the way the server does.
    ///
    /// The item names the product of `product_id`, else the product whose name or alias equals `label`,
    /// else it stays free text. A list that has a manual item for the product answers with that item, unchecked.
    private mutating func addShoppingItem(_ request: LocalRequest, key: String, now: Date) throws -> LocalResult {
        var list = try existing(.shoppingLists, request.id(at: 1))
        var items = list["items"] as? [JSONObject] ?? []
        let label = request.body["label"] as? String
        let product = try (request.body["product_id"] as? Int).map { try existing(.products, $0) } ?? label.flatMap(product(named:))
        let known = product.flatMap { product in
            items.firstIndex { $0["is_manual"] as? Bool == true && ($0["product"] as? JSONObject)?.recordID == product.recordID }
        }
        var created: [Int] = []
        let item: JSONObject
        if let known {
            items[known]["checked_at"] = NSNull()
            item = items[known]
        } else {
            item = manualItem(label: label, product: product, creationKey: key)
            items.append(item)
            created = [item.recordID ?? 0]
        }
        list["items"] = items
        put(.shoppingLists, list)
        itemActionTimes[item.recordID ?? 0] = now
        itemIDsByCreationKey[key] = item.recordID
        return LocalResult(body: resource(shownItem(item)), areas: [.shopping], change: QueuedChange(created: created, shoppingItem: item.recordID))
    }

    /// The shopping list that holds the item with `id`.
    func listHolding(item id: Int) -> JSONObject? {
        all(.shoppingLists).first { ($0["items"] as? [JSONObject] ?? []).contains { $0.recordID == id } }
    }

    /// The item with `id` of any shopping list.
    func shoppingItem(_ id: Int) -> JSONObject? {
        listHolding(item: id).flatMap { ($0["items"] as? [JSONObject] ?? []).first { $0.recordID == id } }
    }

    /// A shopping item with its product as stored now.
    func shownItem(_ item: JSONObject) -> JSONObject {
        var item = item
        if let product = current(.products, item["product"]) as? JSONObject {
            item["product"] = shownProduct(product)
        }
        return item
    }

    /// The product whose name or alias equals `name`, ignoring case; the oldest one if several do.
    func product(named name: String) -> JSONObject? {
        let isName: (String) -> Bool = { $0.caseInsensitiveCompare(name) == .orderedSame }
        let found = all(.products).filter { product in
            (product["name"] as? String).map(isName) == true || (product["aliases"] as? [String] ?? []).contains(where: isName)
        }
        return found.min { ($0.recordID ?? 0) < ($1.recordID ?? 0) }
    }

    /// A manual item as the server would create it; it remembers the key of its creation so that other devices can name it.
    ///
    /// An item added by its product carries no label.
    mutating func manualItem(label: String?, product: JSONObject?, creationKey: String) -> JSONObject {
        [
            "id": makeTemporaryID(), "label": label ?? (product == nil ? "" : NSNull()), "is_manual": true,
            "needed_amount": NSNull(), "purchase_amount": NSNull(), "packages": [JSONObject](), "leftover_amount": 0,
            "wasted_amount": 0, "uses": [JSONObject](), "is_approximate": false, "extra_amounts": [JSONObject](),
            "checked_at": NSNull(), "product": product ?? NSNull(), "creation_key": creationKey,
        ]
    }

    private func missing() throws -> LocalResult? {
        throw failure(404)
    }
}
