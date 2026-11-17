/// A unit in which recipes state quantities.
public struct MeasureUnit: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    /// Language-neutral key; `nil` for units the household added.
    public let key: String?
    /// Abbreviation such as `g` or `EL`.
    public let code: String?
    public let name: String
    public let pluralName: String?
    /// `mass`, `volume` or `product_specific`.
    public let kind: String
    /// Factor to the base unit for mass and volume units.
    public let factorToBase: Double?
}
