/// Settings that apply to everyone in the household.
public struct HouseholdSettings: Decodable, Equatable, Sendable {
    /// Servings assumed until the settings are known.
    public static let fallbackServings = 2
    /// Bounds of the default servings.
    public static let servingsRange = 1...50
    /// Currency assumed until the settings are known or when the server states none.
    public static let fallbackCurrency = "EUR"

    /// Servings recipes are shown, planned and shopped for unless another number is chosen.
    public var defaultServings: Int
    /// ISO 4217 code of the currency prices are given in.
    public var currency: String

    private enum CodingKeys: String, CodingKey {
        case defaultServings, currency
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        defaultServings = try container.decode(Int.self, forKey: .defaultServings)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? Self.fallbackCurrency
    }
}
