import Foundation

/// Unit in which all amounts of a product are given.
public enum BaseUnit: String, Codable, CaseIterable, Sendable {
    case gram = "g"
    case milliliter = "ml"
    case piece
}

/// Whether a value was suggested by the server or confirmed by the household.
public enum ReviewStatus: String, Decodable, Sendable {
    case suggested, confirmed
}

/// Something that can be bought.
///
/// Lists embed a short form; `recipeCount`, `conversions` and `packages` are only
/// present on the detail and review endpoints. Lists that leave out `offers` decode as none.
public struct Product: Decodable, Hashable, Identifiable, Sendable {
    /// Longest note the server stores.
    public static let noteLimit = 500

    public let id: Int
    public let name: String
    public let pluralName: String?
    /// Key of the line icon that pictures the product on the shopping list.
    public let icon: String?
    public let baseUnit: BaseUnit
    public let isPantryStaple: Bool?
    /// Days an opened package stays usable.
    public let shelfLifeOpenedDays: Int?
    /// What the household noted about the product beyond the shops that sell it.
    public var note: String?
    public let status: ReviewStatus
    public let enrichedAt: Date?
    public let recipeCount: Int?
    public let storeSection: StoreSection?
    public let aliases: [String]?
    public let conversions: [ProductConversion]?
    public let packages: [ProductPackage]?
    /// The shops that sell the product, with package size and price.
    public var offers: [ProductOffer]

    private enum CodingKeys: String, CodingKey {
        case id, name, pluralName, icon, baseUnit, isPantryStaple, shelfLifeOpenedDays, note, status
        case enrichedAt, recipeCount, storeSection, aliases, conversions, packages, offers
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        pluralName = try container.decodeIfPresent(String.self, forKey: .pluralName)
        icon = try container.decodeIfPresent(String.self, forKey: .icon)
        baseUnit = try container.decode(BaseUnit.self, forKey: .baseUnit)
        isPantryStaple = try container.decodeIfPresent(Bool.self, forKey: .isPantryStaple)
        shelfLifeOpenedDays = try container.decodeIfPresent(Int.self, forKey: .shelfLifeOpenedDays)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        status = try container.decode(ReviewStatus.self, forKey: .status)
        enrichedAt = try container.decodeIfPresent(Date.self, forKey: .enrichedAt)
        recipeCount = try container.decodeIfPresent(Int.self, forKey: .recipeCount)
        storeSection = try container.decodeIfPresent(StoreSection.self, forKey: .storeSection)
        aliases = try container.decodeIfPresent([String].self, forKey: .aliases)
        conversions = try container.decodeIfPresent([ProductConversion].self, forKey: .conversions)
        packages = try container.decodeIfPresent([ProductPackage].self, forKey: .packages)
        let baseUnit = baseUnit
        offers = (try container.decodeIfPresent([ProductOffer].self, forKey: .offers) ?? []).map { $0.stated(in: baseUnit) }
    }

    /// A note as it is stored: without surrounding space, cut to the limit, `nil` when nothing remains.
    public static func storedNote(_ text: String?) -> String? {
        let text = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(noteLimit)
        return text.isEmpty ? nil : String(text)
    }
}

/// States how much of the base unit one `unit` of a product is.
public struct ProductConversion: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let unit: MeasureUnit
    /// Amount of the base unit; `nil` when the unit cannot be converted for this product.
    public let amountInBase: Double?
    public let status: ReviewStatus
    /// `ai`, `user` or `import`.
    public let source: String
}

/// A package size in which a product is sold.
public struct ProductPackage: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let label: String
    public let amountInBase: Double
    public let status: ReviewStatus
    /// `ai`, `user` or `import`.
    public let source: String
}
