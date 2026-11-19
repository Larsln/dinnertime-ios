/// Where a member stands in a dinner round.
public enum DinnerPhase: Hashable, Sendable {
    /// No round is running.
    case none
    /// The round has no recipes.
    case empty
    /// Cards are left to vote on.
    case voting
    /// The member is through and the others are not.
    case waiting
    /// A second look at what the others liked.
    case second
    /// Nothing is left to decide and there is no match.
    case exhausted
    /// The round has a match.
    case matched

    /// Whether the next step is up to the others or the server, so that the round is asked for again at a slow pace.
    public var isPolled: Bool {
        self == .waiting || self == .second || self == .exhausted
    }

    /// Whether the member has a card to decide on.
    public var isVoting: Bool {
        self == .voting || self == .second
    }
}

/// The card to decide on with its place in the pass that is running.
public struct DinnerDeckPosition: Hashable, Sendable {
    public let card: DinnerRound.Card
    /// Place of the card in the pass, starting at 1.
    public let position: Int
    /// Number of cards of the pass.
    public let total: Int
}

extension DinnerRound {
    /// Cards the member has not voted on yet.
    public var openCards: [Card] {
        cards.filter { $0.myVote == nil }
    }

    /// Cards somebody else liked that the member has not turned down again.
    ///
    /// - Parameter declined: Ids of the recipes turned down in the second pass.
    public func secondChanceCards(declined: Set<Int>) -> [Card] {
        cards.filter { $0.likedByOthers && !declined.contains($0.recipe.id) }
    }

    /// Names of the members who started voting but are not through all cards.
    public var membersBehind: [String] {
        members.filter { $0.votedCount < cards.count }.map(\.name)
    }

    /// Where the member stands, given the recipes turned down in the second pass.
    public func phase(declined: Set<Int> = []) -> DinnerPhase {
        if status == .matched {
            return .matched
        }
        if cards.isEmpty {
            return .empty
        }
        if !openCards.isEmpty {
            return .voting
        }
        if status == .voting {
            return .waiting
        }
        return secondChanceCards(declined: declined).isEmpty ? .exhausted : .second
    }

    /// The card to decide on in the first pass or in the second look; `nil` when the member has none.
    public func deck(declined: Set<Int> = []) -> DinnerDeckPosition? {
        let isSecondLook = phase(declined: declined) == .second
        let remaining = isSecondLook ? secondChanceCards(declined: declined) : openCards
        let total = isSecondLook ? cards.filter(\.likedByOthers).count : cards.count
        return remaining.first.map { DinnerDeckPosition(card: $0, position: total - remaining.count + 1, total: total) }
    }
}

extension Optional where Wrapped == DinnerRound {
    /// Where the member stands; without a round there is none.
    public func phase(declined: Set<Int> = []) -> DinnerPhase {
        map { $0.phase(declined: declined) } ?? .none
    }
}
