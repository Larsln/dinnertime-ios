/// An opened or leftover amount of a product at home.
public struct PantryItem: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    /// Amount in the base unit of the product.
    public let amount: Double
    public let openedOn: DayDate?
    public let expiresOn: DayDate?
    public let product: Product
}
