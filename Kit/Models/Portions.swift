/// How the portion of a meal was for someone who ate it.
public enum PortionVerdict: String, Codable, CaseIterable, Sendable {
    case tooSmall = "too_small"
    case right
    case tooBig = "too_big"
}

/// A member of the household who eats a planned meal.
public struct MealEater: Decodable, Hashable, Sendable {
    public let userID: Int
    /// The name of the member; `nil` when the account is gone.
    public let name: String?
    /// Share of a standard portion that is cooked for the member.
    public let factor: Double

    private enum CodingKeys: String, CodingKey {
        case userID = "userId"
        case name, factor
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(Int.self, forKey: .userID)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        factor = try container.decodeIfPresent(Double.self, forKey: .factor) ?? 1
    }
}

/// What one member said about the portion of a planned meal.
public struct PortionFeedback: Decodable, Hashable, Sendable {
    public let userID: Int
    public let verdict: PortionVerdict

    private enum CodingKeys: String, CodingKey {
        case userID = "userId"
        case verdict
    }
}

/// A member of the household, to choose who eats a meal.
public struct HouseholdMember: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
}
