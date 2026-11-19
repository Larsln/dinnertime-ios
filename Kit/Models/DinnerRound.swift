/// A round in which the household decides what to cook tonight: every member says yes or no to the same recipes.
public struct DinnerRound: Decodable, Hashable, Identifiable, Sendable {
    /// How far a round is.
    public enum Status: String, Decodable, Sendable {
        /// Members still vote.
        case voting
        /// A recipe enough members like was found.
        case matched
        /// Everyone went through all cards without a match.
        case undecided
    }

    /// A recipe to vote on.
    public struct Card: Decodable, Hashable, Sendable {
        public let recipe: RecipeSummary
        /// Number of products the pantry does not cover.
        public let missingCount: Int
        /// The vote of the signed-in user; `nil` until there is one.
        public let myVote: Bool?
        /// Whether somebody else liked the recipe; only told once the round is undecided.
        public let likedByOthers: Bool
    }

    /// A member who takes part, with the number of cards voted on.
    public struct Member: Decodable, Hashable, Sendable {
        public let name: String
        public let votedCount: Int
    }

    public let id: Int
    public let date: DayDate
    /// Whether a single yes is the match.
    public let isSolo: Bool
    public let status: Status
    /// The recipe the round agreed on.
    public let match: RecipeSummary?
    public let cards: [Card]
    public let members: [Member]
}

/// How a round is started.
public struct DinnerRoundOptions: Encodable, Hashable, Sendable {
    /// Longest total time of a recipe when only quick ones are wanted.
    public static let quickMinutes = 30

    /// Whether one person decides alone.
    public var isSolo: Bool
    /// Whether recipes that need shopping are left out.
    public var onlyAvailable: Bool
    /// Longest preparation plus cooking time in minutes; `nil` for no limit.
    public var maxMinutes: Int?

    public init(isSolo: Bool = false, onlyAvailable: Bool = false, maxMinutes: Int? = nil) {
        self.isSolo = isSolo
        self.onlyAvailable = onlyAvailable
        self.maxMinutes = maxMinutes
    }
}
