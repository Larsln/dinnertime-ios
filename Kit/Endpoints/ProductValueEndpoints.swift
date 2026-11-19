import Foundation

/// Unit conversions of a product.
public enum ProductValueEndpoints {
    private struct AmountBody: Encodable {
        let amountInBase: Double?

        private enum CodingKeys: String, CodingKey {
            case amountInBase
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(amountInBase, forKey: .amountInBase)
        }
    }

    /// `PUT /products/{id}/conversions/{unit id}`: states how much of the base unit one unit of the product is.
    ///
    /// Without an amount the unit is marked as not convertible for the product.
    public static func setConversion(productID: Int, unitID: Int, amountInBase: Double?) -> Endpoint<ProductConversion> {
        .resource(.put, "products/\(productID)/conversions/\(unitID)", body: AmountBody(amountInBase: amountInBase))
    }

    /// `DELETE /products/{id}/conversions/{unit id}`: removes a conversion.
    public static func deleteConversion(productID: Int, unitID: Int) -> Endpoint<Void> {
        .empty(.delete, "products/\(productID)/conversions/\(unitID)")
    }
}
