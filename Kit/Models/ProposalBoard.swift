/// The proposals of the planner while the user locks and re-rolls them, before anything is saved.
///
/// Locked proposals survive every new suggestion. Re-rolling one slot keeps all other
/// proposals and avoids every recipe that slot was already offered.
public struct ProposalBoard: Sendable {
    /// Proposals by date and meal.
    public private(set) var proposals: [MealProposal] = []
    /// Number of recipes that match the filters of the last suggestion.
    public private(set) var candidateCount = 0

    private var locked: Set<MealSlot> = []
    private var avoided: [MealSlot: [MealAssignment]] = [:]

    public init() {}

    /// Whether the proposal for `slot` is locked.
    public func isLocked(_ slot: MealSlot) -> Bool {
        locked.contains(slot)
    }

    /// Locks the proposal for `slot` or releases it.
    public mutating func toggleLock(_ slot: MealSlot) {
        if locked.remove(slot) == nil {
            locked.insert(slot)
        }
    }

    /// The request that proposes all slots of `criteria` anew, except the locked ones among them.
    public func request(for criteria: MealPlanCriteria) -> MealPlanSuggestionRequest {
        let wanted = Set(criteria.slots)
        let keep = proposals.filter { locked.contains($0.slot) && wanted.contains($0.slot) }.map(\.assignment)
        return MealPlanSuggestionRequest(criteria, keep: keep)
    }

    /// The request that proposes only `slot` anew: every other proposal is kept and the
    /// recipes the slot was offered so far are avoided.
    public func request(for criteria: MealPlanCriteria, rerolling slot: MealSlot) -> MealPlanSuggestionRequest {
        let keep = proposals.filter { $0.slot != slot }.map(\.assignment)
        let current = proposals.filter { $0.slot == slot }.map(\.assignment)
        return MealPlanSuggestionRequest(criteria, keep: keep, avoid: (avoided[slot] ?? []) + current)
    }

    /// Shows the answer to a request for all slots; locks of slots that got no proposal end.
    public mutating func show(_ suggestions: MealSuggestions) {
        proposals = suggestions.proposals
        candidateCount = suggestions.candidateCount
        locked.formIntersection(proposals.map(\.slot))
        avoided = [:]
    }

    /// Shows the answer to re-rolling `slot`.
    ///
    /// When no other recipe is left for the slot, its proposal stays and the recipes it avoided are offered again.
    public mutating func show(_ suggestions: MealSuggestions, rerolling slot: MealSlot) {
        candidateCount = suggestions.candidateCount
        guard let index = proposals.firstIndex(where: { $0.slot == slot }) else {
            return
        }
        guard let replacement = suggestions.proposals.first(where: { $0.slot == slot }) else {
            avoided[slot] = nil
            return
        }
        avoided[slot, default: []].append(proposals[index].assignment)
        proposals[index] = replacement
    }

    /// The proposals as entries to save, each for `servings`.
    public func entries(servings: Int) -> [MealPlanBatchEntry] {
        proposals.map { MealPlanBatchEntry(date: $0.date, meal: $0.meal, recipeID: $0.recipe.id, servings: servings) }
    }
}
