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

/// What one product of a shopping item needs and what to buy of it.
public protocol ShoppingAmounts {
    var neededAmount: Double? { get }
    var purchaseAmount: Double? { get }
    var packages: [ShoppingListItem.PackagePurchase] { get }
    /// Needs that are bought in addition to the packages or the purchase amount.
    var extraAmounts: [ShoppingListItem.ExtraAmount] { get }
    /// Amount that remains usable after the period.
    var leftoverAmount: Double? { get }
    /// Amount that expires before a recipe uses it.
    var wastedAmount: Double? { get }
    var uses: [ShoppingListItem.Use] { get }
}

/// One position of a shopping list.
///
/// Generated items name a product and the packages to buy. Manual items name a product or
/// carry free text. Items without a product carry no amounts. Products bought as the item's product
/// share the item as its variants, each with amounts of its own.
public struct ShoppingListItem: Decodable, Hashable, Identifiable, Sendable, ShoppingAmounts {
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
    /// Products bought as this one, each with what it needs.
    public let variants: [Variant]
    public var checkedAt: Date?
    public var product: Product?

    /// Whether the item was checked off.
    public var isChecked: Bool {
        checkedAt != nil
    }

    /// Whether the item's product itself is needed, not only its variants.
    public var hasOwnAmounts: Bool {
        purchaseAmount != nil || neededAmount != nil || !extraAmounts.isEmpty
    }

    /// Name to show for the item: its label, else the name of its product.
    public var title: String {
        let label = label.flatMap { $0.isEmpty ? nil : $0 }
        return label ?? product?.name ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case id, label, isManual, neededAmount, purchaseAmount, packages, extraAmounts
        case leftoverAmount, wastedAmount, uses, isApproximate, variants, checkedAt, product
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
        variants = try container.decodeIfPresent([Variant].self, forKey: .variants) ?? []
        checkedAt = try container.decodeIfPresent(Date.self, forKey: .checkedAt)
        product = try container.decodeIfPresent(Product.self, forKey: .product)
    }
}
