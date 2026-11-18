import Foundation

/// The offers of a product: the shops that sell it.
public enum ProductOfferEndpoints {
    /// The values of an offer; a missing size or price is left out when adding and sent as `null` when changing, which clears it.
    private struct OfferBody: Encodable {
        let storeID: Int
        let amountInBase: Double?
        let price: Double?
        let clearsMissing: Bool

        private enum CodingKeys: String, CodingKey {
            case storeID = "storeId"
            case amountInBase, price
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(storeID, forKey: .storeID)
            if clearsMissing {
                try container.encode(amountInBase, forKey: .amountInBase)
                try container.encode(price, forKey: .price)
            } else {
                try container.encodeIfPresent(amountInBase, forKey: .amountInBase)
                try container.encodeIfPresent(price, forKey: .price)
            }
        }
    }

    /// `POST /products/{id}/offers`: states a shop that sells the product, optionally with package size and price.
    public static func add(productID: Int, storeID: Int, amountInBase: Double? = nil, price: Double? = nil) -> Endpoint<ProductOffer> {
        .resource(.post, "products/\(productID)/offers", body: OfferBody(storeID: storeID, amountInBase: amountInBase, price: price, clearsMissing: false))
    }

    /// `PATCH /product-offers/{id}`: corrects an offer; a missing size or price clears the stored one.
    public static func update(id: Int, storeID: Int, amountInBase: Double?, price: Double?) -> Endpoint<ProductOffer> {
        .resource(.patch, "product-offers/\(id)", body: OfferBody(storeID: storeID, amountInBase: amountInBase, price: price, clearsMissing: true))
    }

    /// `DELETE /product-offers/{id}`: removes an offer.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "product-offers/\(id)")
    }
}
