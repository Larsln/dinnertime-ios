import Foundation

/// Formats amounts of products for display.
public struct AmountFormatter: Sendable {
    private static let largeUnitThreshold = 1000.0

    private let locale: Locale

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    /// A number with at most two fraction digits.
    public func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)).grouping(.never).locale(locale))
    }

    /// A number for an input field, with at most three fraction digits, so that it reads back as the same number.
    public func editableNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...3)).grouping(.never).locale(locale))
    }

    /// An amount given in a base unit; large masses and volumes switch to kilograms and liters.
    public func string(_ amount: Double, unit: BaseUnit) -> String {
        switch unit {
        case .gram:
            scaled(amount, switchingAt: amount, small: "g", large: "kg")
        case .milliliter:
            scaled(amount, switchingAt: amount, small: "ml", large: "l")
        case .piece:
            String(localized: "\(number(amount)) pcs", bundle: .kit)
        }
    }

    /// An amount to buy or to have in stock: grams and milliliters are whole numbers and switch to kilograms and
    /// liters with up to two decimals from a rounded thousand upwards, pieces keep their decimals.
    public func wholeString(_ amount: Double, unit: BaseUnit) -> String {
        switch unit {
        case .gram:
            scaled(amount, switchingAt: amount.rounded(), small: "g", large: "kg")
        case .milliliter:
            scaled(amount, switchingAt: amount.rounded(), small: "ml", large: "l")
        case .piece:
            string(amount, unit: unit)
        }
    }

    /// Writes `amount` in the large unit once `shown`, the number that stands in the small unit, reaches a thousand.
    private func scaled(_ amount: Double, switchingAt shown: Double, small: String, large: String) -> String {
        shown >= Self.largeUnitThreshold
            ? "\(number(amount / Self.largeUnitThreshold)) \(large)"
            : "\(number(shown)) \(small)"
    }
}
