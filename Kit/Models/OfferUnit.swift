import Foundation

/// Unit the size of a package is stated in, as the shelf label gives it.
public enum OfferUnit: String, Codable, CaseIterable, Sendable {
    case gram = "g"
    case kilogram = "kg"
    case milliliter = "ml"
    case liter = "l"
    case piece

    /// The unit that states a size in the base unit of a product.
    public init(_ unit: BaseUnit) {
        switch unit {
        case .gram: self = .gram
        case .milliliter: self = .milliliter
        case .piece: self = .piece
        }
    }

    /// The units that measure what a product with `unit` as its base unit is bought by, smallest first.
    public static func choices(for unit: BaseUnit) -> [OfferUnit] {
        switch unit {
        case .gram: [.gram, .kilogram]
        case .milliliter: [.milliliter, .liter]
        case .piece: [.piece]
        }
    }

    /// Whether the unit measures what a product with `unit` as its base unit is bought by.
    public func fits(_ unit: BaseUnit) -> Bool {
        Self.choices(for: unit).contains(self)
    }

    /// Short name of the unit behind a number and in the choice of units.
    public var label: String {
        switch self {
        case .piece: String(localized: "pcs", bundle: .kit)
        default: rawValue
        }
    }
}
