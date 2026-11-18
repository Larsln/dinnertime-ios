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
/// present on the detail and review endpoints.
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
    /// What the household noted about the product, such as a shop, a size or a price.
    public var note: String?
    public let status: ReviewStatus
    public let enrichedAt: Date?
    public let recipeCount: Int?
    public let storeSection: StoreSection?
    public let aliases: [String]?
    public let conversions: [ProductConversion]?
    public let packages: [ProductPackage]?

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
