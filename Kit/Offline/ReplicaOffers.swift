import Foundation

/// The package sizes of the products and the shops that sell them: writes to the offers of a product, on the local copy.
extension Replica {
    private static let offerFields = ["store_id", "price"]

    /// The size a write states for an offer of `product`, as the fields to store; empty when the write names no size.
    ///
    /// A size without a unit is taken in the base unit of the product, and without a size no unit is kept.
    private func statedSize(in body: JSONObject, of product: JSONObject) -> JSONObject {
        guard let amount = body["amount"] else {
            return [:]
        }
        guard !(amount is NSNull) else {
            return ["amount": NSNull(), "unit": NSNull()]
        }
        return ["amount": amount, "unit": body["unit"] as? String ?? product["base_unit"] ?? NSNull()]
    }

    /// The shop a write names by its id; `nil` for a size sold everywhere, and the failure of the server for a shop the copy does not hold.
    private func statedStore(in body: JSONObject) throws -> JSONObject? {
        guard let id = body["store_id"], !(id is NSNull) else {
            return nil
        }
        return try existing(.stores, id as? Int)
    }

    /// An offer with the name of its shop as stored now and whether the household buys there at the moment.
    ///
    /// A size sold everywhere and an offer whose shop the copy does not hold stay as they are and count as active.
    func shownOffer(_ offer: JSONObject) -> JSONObject {
        guard let store = (offer["store_id"] as? Int).flatMap({ record(.stores, $0) }) else {
            return offer
        }
        return offer.merging(["store": store["name"] ?? "", "store_is_active": store["is_active"] as? Bool ?? true]) { _, new in new }
    }

    /// Answers a write to an offer of a product; `nil` for other calls.
    mutating func writeOffer(_ request: LocalRequest) throws -> LocalResult? {
        if request.matches(.post, "products", "*", "offers") {
            var product = try existing(.products, request.id(at: 1))
            let store = try statedStore(in: request.body)
            let size = statedSize(in: request.body, of: product)
            let offer: JSONObject = [
                "id": makeTemporaryID(), "store_id": store?.recordID ?? NSNull(), "store": store?["name"] ?? NSNull(),
                "amount": size["amount"] ?? NSNull(), "unit": size["unit"] ?? NSNull(), "price": request.body["price"] ?? NSNull(),
            ]
            product["offers"] = offers(of: product) + [offer]
            put(.products, product)
            return LocalResult(body: resource(shownOffer(offer)), areas: [.products, .shopping], change: QueuedChange(created: [offer.recordID ?? 0]))
        }
        guard request.matches(.patch, "product-offers", "*") || request.matches(.delete, "product-offers", "*") else {
            return nil
        }
        let id = request.id(at: 1)
        guard var product = productHolding(offer: id) else {
            throw failure(404)
        }
        var offers = offers(of: product)
        var answer: Any?
        if let index = offers.firstIndex(where: { $0.recordID == id }) {
            if request.method == .delete {
                offers.remove(at: index)
            } else {
                if request.body["store_id"] != nil {
                    offers[index]["store"] = try statedStore(in: request.body)?["name"] ?? NSNull()
                }
                let size = statedSize(in: request.body, of: product)
                if !size.isEmpty {
                    offers[index]["amount_in_base"] = nil
                }
                offers[index].merge(request.body.filter { Self.offerFields.contains($0.key) }) { _, new in new }
                offers[index].merge(size) { _, new in new }
                answer = resource(shownOffer(offers[index]))
            }
        }
        product["offers"] = offers
        put(.products, product)
        return LocalResult(body: answer, areas: [.products, .shopping], change: QueuedChange())
    }

    /// The product that holds the offer with `id`.
    func productHolding(offer id: Int?) -> JSONObject? {
        all(.products).first { offers(of: $0).contains { $0.recordID == id } }
    }

    /// The products with an offer of the shop with `id`.
    func productsHolding(offersOf id: Int?) -> [JSONObject] {
        guard let id else {
            return []
        }
        return all(.products).filter { offers(of: $0).contains { $0["store_id"] as? Int == id } }
    }

    /// The offers a product record carries.
    func offers(of product: JSONObject) -> [JSONObject] {
        product["offers"] as? [JSONObject] ?? []
    }
}
