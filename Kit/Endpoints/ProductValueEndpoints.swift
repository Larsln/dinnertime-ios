import Foundation

/// Unit conversions and package sizes of a product.
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

    private struct PackageBody: Encodable {
        let label: String
        let amountInBase: Double
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

    /// `POST /products/{id}/packages`: adds a package size.
    public static func addPackage(productID: Int, label: String, amountInBase: Double) -> Endpoint<ProductPackage> {
        .resource(.post, "products/\(productID)/packages", body: PackageBody(label: label, amountInBase: amountInBase))
    }

    /// `PATCH /product-packages/{id}`: corrects a package size.
    public static func updatePackage(id: Int, label: String, amountInBase: Double) -> Endpoint<ProductPackage> {
        .resource(.patch, "product-packages/\(id)", body: PackageBody(label: label, amountInBase: amountInBase))
    }

    /// `DELETE /product-packages/{id}`: removes a package size.
    public static func deletePackage(id: Int) -> Endpoint<Void> {
        .empty(.delete, "product-packages/\(id)")
    }
}
