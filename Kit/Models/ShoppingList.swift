import Foundation

/// The shopping list of one planning period.
public struct ShoppingList: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let startsOn: DayDate
    public let endsOn: DayDate
    /// When the leftovers were moved to the pantry.
    public let leftoversStockedAt: Date?
    /// What the meals of the period need that is at home already, by name.
    public let inStock: [StockedNeed]
    /// Positions in walking order through the store.
    public var items: [ShoppingListItem]

    private enum CodingKeys: String, CodingKey {
        case id, startsOn, endsOn, leftoversStockedAt, inStock, items
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        startsOn = try container.decode(DayDate.self, forKey: .startsOn)
        endsOn = try container.decode(DayDate.self, forKey: .endsOn)
        leftoversStockedAt = try container.decodeIfPresent(Date.self, forKey: .leftoversStockedAt)
        inStock = try container.decodeIfPresent([StockedNeed].self, forKey: .inStock) ?? []
        items = try container.decode([ShoppingListItem].self, forKey: .items)
    }
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
///
/// An item is settled by checking it off or by skipping it. A skipped one is not bought at all, and one
/// checked off with a substitute was replaced by something else.
public struct ShoppingListItem: Decodable, Hashable, Identifiable, Sendable, ShoppingAmounts {
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
    /// When the item was struck off the list without buying it.
    public var skippedAt: Date?
    /// What was bought in place of the item's product.
    public var substitute: Substitute?
    public var product: Product?

    /// Whether the item was checked off.
    public var isChecked: Bool {
        checkedAt != nil
    }

    /// Whether the item was struck off the list without buying it.
    public var isSkipped: Bool {
        skippedAt != nil
    }

    /// Whether nothing is left to do about the item.
    public var isSettled: Bool {
        isChecked || isSkipped
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
        case leftoverAmount, wastedAmount, uses, isApproximate, variants, checkedAt, skippedAt, substitute, product
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
        skippedAt = try container.decodeIfPresent(Date.self, forKey: .skippedAt)
        substitute = try container.decodeIfPresent(Substitute.self, forKey: .substitute)
        product = try container.decodeIfPresent(Product.self, forKey: .product)
    }
}
