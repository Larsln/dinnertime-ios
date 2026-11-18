import Foundation

/// The shopping list of one planning period.
public struct ShoppingList: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let startsOn: DayDate
    public let endsOn: DayDate
    /// When the leftovers were moved to the pantry.
    public let leftoversStockedAt: Date?
    /// Positions in walking order through the store.
    public var items: [ShoppingListItem]
}

/// One position of a shopping list.
///
/// Generated items name a product and the packages to buy. Manual items name a product or
/// carry free text. Items without a product carry no amounts.
public struct ShoppingListItem: Decodable, Hashable, Identifiable, Sendable {
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

    public let id: Int
    public let label: String?
    public let isManual: Bool
    public let neededAmount: Double?
    public let purchaseAmount: Double?
    public let packages: [PackagePurchase]
    /// Needs that are bought in addition to the packages or the purchase amount.
    public let extraAmounts: [ExtraAmount]
    /// Amount that remains usable after the period.
    public let leftoverAmount: Double?
    /// Amount that expires before a recipe uses it.
    public let wastedAmount: Double?
    public let uses: [Use]
    /// Whether the amounts rest on unconfirmed conversions.
    public let isApproximate: Bool
    public var checkedAt: Date?
    public var product: Product?

    /// Whether the item was checked off.
    public var isChecked: Bool {
        checkedAt != nil
    }

    /// Name to show for the item: its label, else the name of its product.
    public var title: String {
        let label = label.flatMap { $0.isEmpty ? nil : $0 }
        return label ?? product?.name ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id, label, isManual, neededAmount, purchaseAmount, packages, extraAmounts
        case leftoverAmount, wastedAmount, uses, isApproximate, checkedAt, product
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        isManual = try container.decode(Bool.self, forKey: .isManual)
        neededAmount = try container.decodeIfPresent(Double.self, forKey: .neededAmount)
        purchaseAmount = try container.decodeIfPresent(Double.self, forKey: .purchaseAmount)
        packages = try container.decodeIfPresent([PackagePurchase].self, forKey: .packages) ?? []
        extraAmounts = try container.decodeIfPresent([ExtraAmount].self, forKey: .extraAmounts) ?? []
        leftoverAmount = try container.decodeIfPresent(Double.self, forKey: .leftoverAmount)
        wastedAmount = try container.decodeIfPresent(Double.self, forKey: .wastedAmount)
        uses = try container.decodeIfPresent([Use].self, forKey: .uses) ?? []
        isApproximate = try container.decodeIfPresent(Bool.self, forKey: .isApproximate) ?? false
        checkedAt = try container.decodeIfPresent(Date.self, forKey: .checkedAt)
        product = try container.decodeIfPresent(Product.self, forKey: .product)
    }
}
