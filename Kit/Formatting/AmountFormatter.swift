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
            scaled(amount, small: "g", large: "kg")
        case .milliliter:
            scaled(amount, small: "ml", large: "l")
        case .piece:
            String(localized: "\(number(amount)) pcs", bundle: .kit)
        }
    }

    private func scaled(_ amount: Double, small: String, large: String) -> String {
        amount >= Self.largeUnitThreshold
            ? "\(number(amount / Self.largeUnitThreshold)) \(large)"
            : "\(number(amount)) \(small)"
    }
}
