import Foundation

/// The shops that sell the products: writes to the offers of a product and the names of the shops in use, on the local copy.
extension Replica {
    private static let offerFields = ["store", "amount_in_base", "price"]

    /// The names of the shops the offers of all products name, most used first and equally used ones by name.
    var knownStores: [String] {
        let names = all(.products).flatMap { offers(of: $0) }.compactMap { $0["store"] as? String }
        let uses = Dictionary(names.map { ($0, 1) }, uniquingKeysWith: +)
        return uses.keys.sorted { first, second in
            let (firstUses, secondUses) = (uses[first] ?? 0, uses[second] ?? 0)
            return firstUses == secondUses ? first.localizedStandardCompare(second) == .orderedAscending : firstUses > secondUses
        }
    }

    /// Answers a write to an offer of a product; `nil` for other calls.
    mutating func writeOffer(_ request: LocalRequest) throws -> LocalResult? {
        if request.matches(.post, "products", "*", "offers") {
            var product = try existing(.products, request.id(at: 1))
            let offer: JSONObject = [
                "id": makeTemporaryID(), "store": request.body["store"] ?? "",
                "amount_in_base": request.body["amount_in_base"] ?? NSNull(), "price": request.body["price"] ?? NSNull(),
            ]
            product["offers"] = offers(of: product) + [offer]
            put(.products, product)
            return LocalResult(body: resource(offer), areas: [.products, .shopping], change: QueuedChange(created: [offer.recordID ?? 0]))
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
                offers[index].merge(request.body.filter { Self.offerFields.contains($0.key) }) { _, new in new }
                answer = resource(offers[index])
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

    private func offers(of product: JSONObject) -> [JSONObject] {
        product["offers"] as? [JSONObject] ?? []
    }
}
