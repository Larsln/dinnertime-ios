import Foundation

/// A product the meals of a shopping list need that is not bought: the pantry covers it, or it is permanently in stock.
public struct StockedNeed: Decodable, Hashable, Identifiable, Sendable {
    /// A planned recipe that uses the product.
    public struct Use: Decodable, Hashable, Sendable {
        public let date: DayDate
        public let recipeID: Int
        public let title: String
        /// Amount the recipe consumes; `nil` for staples, whose amounts are not tracked.
        public let amount: Double?

        private enum CodingKeys: String, CodingKey {
            case date, title, amount
            case recipeID = "recipeId"
        }
    }

    public let productID: Int
    public let name: String
    public let baseUnit: BaseUnit
    /// Amount all meals consume together; `nil` for staples and needs without an amount.
    public let neededAmount: Double?
    /// Whether the product is permanently in stock.
    public let isStaple: Bool
    public let uses: [Use]

    public var id: Int {
        productID
    }

    private enum CodingKeys: String, CodingKey {
        case name, baseUnit, neededAmount, isStaple, uses
        case productID = "productId"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productID = try container.decode(Int.self, forKey: .productID)
        name = try container.decode(String.self, forKey: .name)
        baseUnit = try container.decode(BaseUnit.self, forKey: .baseUnit)
        neededAmount = try container.decodeIfPresent(Double.self, forKey: .neededAmount)
        isStaple = try container.decodeIfPresent(Bool.self, forKey: .isStaple) ?? false
        uses = try container.decodeIfPresent([Use].self, forKey: .uses) ?? []
    }

    /// The name with the needed amount, such as "Reis 150 g"; the name alone when no amount is known.
    public func text(formatter: AmountFormatter = AmountFormatter()) -> String {
        neededAmount.map { "\(name) \(formatter.string($0, unit: baseUnit))" } ?? name
    }
}
