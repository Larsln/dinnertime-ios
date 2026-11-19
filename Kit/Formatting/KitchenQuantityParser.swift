import Foundation

extension KitchenQuantity {
    /// Reads a quantity as a cook types it: "1/2", "1 1/2", "½", "1½", "1,5", "0.25" or "3".
    ///
    /// Returns `nil` for empty, negative or unreadable input and for a zero denominator.
    public static func parse(_ text: String) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return glyphValue(of: trimmed) ?? writtenFractionValue(of: trimmed) ?? decimalValue(of: trimmed)
    }

    /// The value of an optional whole number followed by a fraction glyph.
    private static func glyphValue(of text: String) -> Double? {
        guard let last = text.last, let fraction = fractions.first(where: { $0.glyph == last }) else {
            return nil
        }
        let whole = text.dropLast()
        guard let match = whole.wholeMatch(of: /(\d*)\s*/.asciiOnlyDigits()) else {
            return nil
        }
        guard !match.output.1.isEmpty else {
            return whole.isEmpty ? fraction.value : nil
        }
        return Double(match.output.1).map { $0 + fraction.value }
    }

    /// The value of an optional whole number followed by a fraction written with a slash.
    private static func writtenFractionValue(of text: String) -> Double? {
        guard let match = text.wholeMatch(of: /(?:(\d+)\s+)?(\d+)\/(\d+)/.asciiOnlyDigits()),
              let numerator = Double(match.output.2), let denominator = Double(match.output.3), denominator != 0
        else {
            return nil
        }
        return (match.output.1.flatMap { Double($0) } ?? 0) + numerator / denominator
    }

    /// The value of a whole number or a decimal with comma or dot.
    private static func decimalValue(of text: String) -> Double? {
        guard text.wholeMatch(of: /\d+(?:[.,]\d+)?/.asciiOnlyDigits()) != nil else {
            return nil
        }
        return Double(text.replacing(",", with: "."))
    }
}
