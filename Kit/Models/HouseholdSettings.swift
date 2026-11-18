/// Settings that apply to everyone in the household.
public struct HouseholdSettings: Decodable, Equatable, Sendable {
    /// Servings assumed until the settings are known.
    public static let fallbackServings = 2
    /// Bounds of the default servings.
    public static let servingsRange = 1...50

    /// Servings recipes are shown, planned and shopped for unless another number is chosen.
    public var defaultServings: Int
}
