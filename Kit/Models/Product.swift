import Foundation

/// Unit in which all amounts of a product are given.
public enum BaseUnit: String, Decodable, Sendable {
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
    public let id: Int
    public let name: String
    public let pluralName: String?
    public let baseUnit: BaseUnit
    public let isPantryStaple: Bool?
    /// Days an opened package stays usable.
    public let shelfLifeOpenedDays: Int?
    public let status: ReviewStatus
    public let enrichedAt: Date?
    public let recipeCount: Int?
    public let storeSection: StoreSection?
    public let aliases: [String]?
    public let conversions: [ProductConversion]?
    public let packages: [ProductPackage]?
}

/// States how much of the base unit one `unit` of a product is.
public struct ProductConversion: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let unit: MeasureUnit
    public let amountInBase: Double
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
