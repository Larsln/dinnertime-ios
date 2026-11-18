import Foundation

extension ProductOffer {
    /// The offer in one line, such as "Lidl · 225 g · 2,59 €"; a missing size or price is left out.
    public func text(unit: BaseUnit, amounts: AmountFormatter = AmountFormatter(), prices: PriceFormatter = PriceFormatter()) -> String {
        let parts = [store, amountInBase.map { amounts.string($0, unit: unit) }, price.map(prices.string)]
        return parts.compactMap { $0 }.joined(separator: " · ")
    }
}

/// Reading of numbers the user typed on a number pad.
public enum NumberInput {
    /// The number a text states, with a comma or a point before the decimals; `nil` for anything else and for negative numbers.
    public static func value(_ text: String) -> Double? {
        let text = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let value = Double(text), value.isFinite, value >= 0 else {
            return nil
        }
        return value
    }

    /// The price a text states, rounded to two decimals.
    public static func price(_ text: String) -> Double? {
        value(text).map { ($0 * 100).rounded() / 100 }
    }
}

extension AmountFormatter {
    /// A number as it is put into an input field: with the decimal separator of the locale and without grouping.
    public func input(_ value: Double?) -> String {
        value.map(number) ?? ""
    }
}
