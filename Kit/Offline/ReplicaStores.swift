import Foundation

/// The shops of the household on the local copy: how they are shown and the writes to them.
extension Replica {
    /// A shop with the number of offers noted for it.
    func shownStore(_ store: JSONObject) -> JSONObject {
        var store = store
        store["offer_count"] = all(.products).reduce(0) { count, product in
            count + offers(of: product).filter { $0["store_id"] as? Int == store.recordID }.count
        }
        return store
    }

    /// Answers a write to a shop; `nil` for other calls.
    mutating func writeStore(_ request: LocalRequest) throws -> LocalResult? {
        if request.matches(.post, "stores") {
            let name = request.body["name"] as? String ?? ""
            try requireUnusedStoreName(name, except: nil)
            let store: JSONObject = ["id": makeTemporaryID(), "name": name, "is_active": request.body["is_active"] as? Bool ?? true]
            put(.stores, store)
            return LocalResult(body: resource(shownStore(store)), areas: [.products], change: QueuedChange(created: [store.recordID ?? 0], createdKind: .stores))
        }
        if request.matches(.patch, "stores", "*") {
            var store = try existing(.stores, request.id(at: 1))
            if let name = request.body["name"] as? String {
                try requireUnusedStoreName(name, except: store.recordID)
            }
            store.merge(request.body.filter { ["name", "is_active"].contains($0.key) }) { _, new in new }
            put(.stores, store)
            return LocalResult(body: resource(shownStore(store)), areas: [.products, .shopping], change: QueuedChange())
        }
        if request.matches(.delete, "stores", "*") {
            let store = try existing(.stores, request.id(at: 1))
            removeOffers(ofStore: store.recordID)
            remove(.stores, store.recordID ?? 0)
            return LocalResult(areas: [.products, .shopping], change: QueuedChange())
        }
        return nil
    }

    /// Takes the offers of the shop with `id` off all products.
    mutating func removeOffers(ofStore id: Int?) {
        for var product in productsHolding(offersOf: id) {
            product["offers"] = offers(of: product).filter { $0["store_id"] as? Int != id }
            put(.products, product)
        }
    }

    /// Fails the way the server does when another shop than `id` carries `name`, ignoring case.
    private func requireUnusedStoreName(_ name: String, except id: Int?) throws {
        let isTaken = all(.stores).contains { $0.recordID != id && ($0["name"] as? String)?.caseInsensitiveCompare(name) == .orderedSame }
        if isTaken {
            throw APIError.validation(message: String(localized: "A store with this name exists already.", bundle: .kit), fields: [:])
        }
    }
}
