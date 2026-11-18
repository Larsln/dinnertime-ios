import Foundation

/// Formats prices in the currency of the household for display.
public struct PriceFormatter: Sendable {
    private let currencyCode: String
    private let locale: Locale

    public init(currencyCode: String = HouseholdSettings.fallbackCurrency, locale: Locale = .current) {
        self.currencyCode = currencyCode
        self.locale = locale
    }

    /// A price with the sign of the currency, such as "2,59 €".
    public func string(_ price: Double) -> String {
        price.formatted(.currency(code: currencyCode).locale(locale))
    }

    /// The sign of the currency, to stand next to an input field.
    public var symbol: String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? currencyCode
    }
}
