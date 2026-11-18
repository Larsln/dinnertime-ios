/// The editable values of a product as `PATCH /products/{id}` accepts them.
///
/// A missing icon, store section or shelf life is sent as `null` so that it clears the stored value.
public struct ProductInput: Encodable, Equatable, Sendable {
    public var name: String
    /// Key of the line icon on the shopping list; `nil` shows the icon of the store section.
    public var icon: String?
    public var storeSectionID: Int?
    public var baseUnit: BaseUnit
    public var isPantryStaple: Bool
    /// Days an opened package stays usable; `nil` for products that keep.
    public var shelfLifeOpenedDays: Int?

    public init(name: String, icon: String?, storeSectionID: Int?, baseUnit: BaseUnit, isPantryStaple: Bool, shelfLifeOpenedDays: Int?) {
        self.name = name
        self.icon = icon
        self.storeSectionID = storeSectionID
        self.baseUnit = baseUnit
        self.isPantryStaple = isPantryStaple
        self.shelfLifeOpenedDays = shelfLifeOpenedDays
    }

    private enum CodingKeys: String, CodingKey {
        case name, icon, baseUnit, isPantryStaple, shelfLifeOpenedDays
        case storeSectionID = "storeSectionId"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(storeSectionID, forKey: .storeSectionID)
        try container.encode(baseUnit, forKey: .baseUnit)
        try container.encode(isPantryStaple, forKey: .isPantryStaple)
        try container.encode(shelfLifeOpenedDays, forKey: .shelfLifeOpenedDays)
    }
}
