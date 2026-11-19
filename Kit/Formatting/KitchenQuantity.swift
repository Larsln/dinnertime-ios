import Foundation

/// Writes and reads quantities the way cooks do: whole numbers and common fractions as glyphs such as "1 ½".
///
/// Quantities stay decimal numbers everywhere else; this only concerns what is shown and typed.
public enum KitchenQuantity {
    /// How a quantity is written.
    public enum Style: Sendable {
        /// Prefers fractions such as ½.
        case kitchen
        /// Always uses decimals, for weights and volumes.
        case metric
    }

    /// The fractions that have a glyph of their own.
    static let fractions: [(value: Double, glyph: Character)] = [
        (1.0 / 2, "½"), (1.0 / 3, "⅓"), (2.0 / 3, "⅔"), (1.0 / 4, "¼"), (3.0 / 4, "¾"),
        (1.0 / 8, "⅛"), (3.0 / 8, "⅜"), (5.0 / 8, "⅝"), (7.0 / 8, "⅞"),
    ]

    private static let tolerance = 0.02
    private static let editableFractionLimit = 1000.0
    /// Narrow no-break space between the whole number and the fraction.
    private static let separator = "\u{202F}"

    /// A quantity for display: a whole number or a fraction glyph where the value is close to one,
    /// else a decimal with at most two fraction digits. The metric style never uses fractions.
    public static func format(_ value: Double, style: Style = .kitchen, formatter: AmountFormatter = AmountFormatter()) -> String {
        let fraction = style == .kitchen ? fractionText(value, formatter: formatter) : nil
        return fraction ?? formatter.number(value)
    }

    /// A quantity for an input field: like ``format(_:style:formatter:)``, but decimals carry up to
    /// three fraction digits, so that the text reads back as the same number.
    public static func editable(_ value: Double, style: Style = .kitchen, formatter: AmountFormatter = AmountFormatter()) -> String {
        let fraction = style == .kitchen && value < editableFractionLimit ? fractionText(value, formatter: formatter) : nil
        return fraction ?? formatter.editableNumber(value)
    }

    /// The whole number or fraction glyph for a value; `nil` when it is negative or neither whole nor close to a known fraction.
    private static func fractionText(_ value: Double, formatter: AmountFormatter) -> String? {
        guard value.isFinite, value >= 0 else {
            return nil
        }
        let whole = (value + tolerance).rounded(.down)
        let rest = value - whole
        let wholeText = formatter.number(whole)
        if abs(rest) < tolerance {
            return wholeText
        }
        guard let fraction = fractions.first(where: { abs(rest - $0.value) < tolerance }) else {
            return nil
        }
        return whole == 0 ? String(fraction.glyph) : "\(wholeText)\(separator)\(fraction.glyph)"
    }
}

extension Optional where Wrapped == MeasureUnit {
    /// How quantities in the unit are written: weights and volumes as decimals, everything else,
    /// including no unit at all, with kitchen fractions.
    public var quantityStyle: KitchenQuantity.Style {
        self?.kind == "mass" || self?.kind == "volume" ? .metric : .kitchen
    }
}
