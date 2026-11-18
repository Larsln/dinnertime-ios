import MealplannerKit
import Observation

/// The state of planning a week in three steps: days, preferences and the preview of the proposals.
///
/// Nothing is saved before the proposals are accepted in the last step.
@MainActor
@Observable
final class PlanWizardModel: ErrorReporting {
    /// The steps in their order.
    enum Step: Int, CaseIterable {
        case days, preferences, preview
    }

    var errorMessage: String?
    var step = Step.days
    /// The slots chosen in the first step.
    var selection: MealSlotSelection
    var servings = 2
    var preferences = MealPlanPreferences()
    /// Keys of the courses the proposals are restricted to.
    var courseKeys: [String] = []
    /// Tags the proposals are restricted to.
    var tagIDs: [Int] = []
    /// Whether the shopping list of the week is created after saving.
    var createsShoppingList = false
    private(set) var board = ProposalBoard()
    private(set) var courses: [Course] = []
    private(set) var tags: [Tag] = []
    private(set) var isWorking = false

    let weeks: WeekSelection
    private let plan: PlanModel
    private let session: AppSession

    init(session: AppSession, weeks: WeekSelection, plan: PlanModel) {
        self.session = session
        self.weeks = weeks
        self.plan = plan
        selection = Self.openDinners(of: weeks.week, planned: plan.plannedSlots, showsAllMeals: false)
    }

    /// The slots of the shown week that have an entry.
    var plannedSlots: Set<MealSlot> {
        plan.plannedSlots
    }

    /// Starts over with the open dinners of the shown week, after the week or its entries changed.
    func resetSelection() {
        selection = Self.openDinners(of: weeks.week, planned: plan.plannedSlots, showsAllMeals: selection.showsAllMeals)
    }

    /// Loads the courses and tags the proposals can be restricted to.
    func loadOptions() async {
        await attempt {
            courses = try await session.send(ReferenceEndpoints.courses)
            tags = try await session.send(ReferenceEndpoints.tags).filter { $0.type == .tag }
        }
    }

    /// Asks for proposals for the chosen slots, keeping locked ones, and shows the preview.
    func suggest() async {
        await work {
            board.show(try await session.send(MealPlanEndpoints.suggest(board.request(for: criteria))))
            step = .preview
        }
    }

    /// Asks for another recipe for one slot.
    func reroll(_ slot: MealSlot) async {
        await work {
            let request = board.request(for: criteria, rerolling: slot)
            board.show(try await session.send(MealPlanEndpoints.suggest(request)), rerolling: slot)
        }
    }

    /// Locks the proposal for a slot or releases it.
    func toggleLock(_ slot: MealSlot) {
        board.toggleLock(slot)
    }

    /// Saves the proposals as plan entries; returns whether the server accepted them.
    func save() async -> Bool {
        await work {
            _ = try await session.send(MealPlanEndpoints.save(board.entries(servings: servings)))
        }
    }

    private var criteria: MealPlanCriteria {
        MealPlanCriteria(
            from: weeks.week.start,
            to: weeks.week.end,
            servings: servings,
            slots: selection.slots,
            preferences: preferences,
            tagIDs: tagIDs,
            courses: courseKeys
        )
    }

    /// The matrix of `week` with the dinners selected that have no entry yet.
    private static func openDinners(of week: Week, planned: Set<MealSlot>, showsAllMeals: Bool) -> MealSlotSelection {
        var selection = MealSlotSelection(days: week.days, planned: planned)
        selection.showsAllMeals = showsAllMeals
        selection.apply(.allDays)
        selection.apply(.dinner)
        return selection
    }

    @discardableResult
    private func work(_ operation: () async throws -> Void) async -> Bool {
        isWorking = true
        defer { isWorking = false }
        return await attempt(operation)
    }
}
