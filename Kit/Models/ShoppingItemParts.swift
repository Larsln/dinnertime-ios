import Foundation

/// What the amounts of a shopping item are made of, and what may stand in for it.
extension ShoppingListItem {
    /// A package size and how often to buy it.
    public struct PackagePurchase: Decodable, Hashable, Sendable {
        public let packageID: Int?
        public let label: String
        public let amount: Double
        public let count: Int

        private enum CodingKeys: String, CodingKey {
            case label, amount, count
            case packageID = "packageId"
        }
    }

    /// A planned recipe that consumes part of the item.
    public struct Use: Decodable, Hashable, Sendable {
        public let date: DayDate
        public let recipeID: Int
        public let title: String
        public let amount: Double

        private enum CodingKeys: String, CodingKey {
            case date, title, amount
            case recipeID = "recipeId"
        }
    }

    /// A need in a recipe unit that cannot be converted for the product and is bought in addition.
    public struct ExtraAmount: Decodable, Hashable, Sendable {
        public let quantity: Double
        public let unitCode: String
    }

    /// A product bought as the item's product, such as red onions on the item of onions.
    public struct Variant: Decodable, Hashable, Identifiable, Sendable, ShoppingAmounts {
        public let productID: Int
        public let name: String
        public let baseUnit: BaseUnit
        public let neededAmount: Double?
        public let purchaseAmount: Double?
        public let packages: [PackagePurchase]
        public let extraAmounts: [ExtraAmount]
        public let leftoverAmount: Double?
        public let wastedAmount: Double?
        public let uses: [Use]

        public var id: Int {
            productID
        }

        private enum CodingKeys: String, CodingKey {
            case name, baseUnit, neededAmount, purchaseAmount, packages, extraAmounts, leftoverAmount, wastedAmount, uses
            case productID = "productId"
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            productID = try container.decode(Int.self, forKey: .productID)
            name = try container.decode(String.self, forKey: .name)
            baseUnit = try container.decode(BaseUnit.self, forKey: .baseUnit)
            neededAmount = try container.decodeIfPresent(Double.self, forKey: .neededAmount)
            purchaseAmount = try container.decodeIfPresent(Double.self, forKey: .purchaseAmount)
            packages = try container.decodeIfPresent([PackagePurchase].self, forKey: .packages) ?? []
            extraAmounts = try container.decodeIfPresent([ExtraAmount].self, forKey: .extraAmounts) ?? []
            leftoverAmount = try container.decodeIfPresent(Double.self, forKey: .leftoverAmount)
            wastedAmount = try container.decodeIfPresent(Double.self, forKey: .wastedAmount)
            uses = try container.decodeIfPresent([Use].self, forKey: .uses) ?? []
        }
    }

    /// What was bought in place of an item: a product, or something only named.
    public struct Substitute: Decodable, Hashable, Sendable {
        public let productID: Int?
        public let name: String

        public init(productID: Int?, name: String) {
            self.productID = productID
            self.name = name
        }

        private enum CodingKeys: String, CodingKey {
            case name
            case productID = "productId"
        }
    }
}
