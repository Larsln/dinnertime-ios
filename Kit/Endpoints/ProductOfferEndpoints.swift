import Foundation

/// The offers of a product: the package sizes it is sold in and the shops that sell them.
public enum ProductOfferEndpoints {
    /// The values of an offer; a missing shop, size or price is left out when adding and sent as `null` when changing, which clears it.
    ///
    /// Without a shop the size is one sold everywhere.
    /// The unit goes with the size: without a size none is sent.
    private struct OfferBody: Encodable {
        let storeID: Int?
        let amount: Double?
        let unit: OfferUnit?
        let price: Double?
        let clearsMissing: Bool

        init(storeID: Int?, amount: Double?, unit: OfferUnit?, price: Double?, clearsMissing: Bool) {
            self.storeID = storeID
            self.amount = amount
            self.unit = amount == nil ? nil : unit
            self.price = price
            self.clearsMissing = clearsMissing
        }

        private enum CodingKeys: String, CodingKey {
            case storeID = "storeId"
            case amount, unit, price
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if clearsMissing {
                try container.encode(storeID, forKey: .storeID)
                try container.encode(amount, forKey: .amount)
                try container.encode(unit, forKey: .unit)
                try container.encode(price, forKey: .price)
            } else {
                try container.encodeIfPresent(storeID, forKey: .storeID)
                try container.encodeIfPresent(amount, forKey: .amount)
                try container.encodeIfPresent(unit, forKey: .unit)
                try container.encodeIfPresent(price, forKey: .price)
            }
        }
    }

    /// `POST /products/{id}/offers`: states a package the product is sold in, at a shop or, without one, everywhere.
    ///
    /// A size without a unit is taken in the base unit of the product.
    public static func add(productID: Int, storeID: Int? = nil, amount: Double? = nil, unit: OfferUnit? = nil, price: Double? = nil) -> Endpoint<ProductOffer> {
        .resource(.post, "products/\(productID)/offers", body: OfferBody(storeID: storeID, amount: amount, unit: unit, price: price, clearsMissing: false))
    }

    /// `PATCH /product-offers/{id}`: corrects an offer; a missing shop, size or price clears the stored one.
    public static func update(id: Int, storeID: Int?, amount: Double?, unit: OfferUnit?, price: Double?) -> Endpoint<ProductOffer> {
        .resource(.patch, "product-offers/\(id)", body: OfferBody(storeID: storeID, amount: amount, unit: unit, price: price, clearsMissing: true))
    }

    /// `DELETE /product-offers/{id}`: removes an offer.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "product-offers/\(id)")
    }
}
