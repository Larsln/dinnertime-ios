import DinnertimeKit
import Observation

/// Loads and changes the meal plan of one week, with why each meal goes with the others.
///
/// Every change reloads the week, since moving one meal can change what the others share; the server
/// adjusts the shopping list on its own.
@MainActor
@Observable
final class PlanModel: ErrorReporting {
    var errorMessage: String?
    private(set) var entries: [MealPlanEntry] = []
    /// Why each entry goes with the others, by entry id; empty while the server cannot be reached.
    private(set) var reasons: [Int: [PlanReason]] = [:]

    private var week: Week?
    let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// The meals of one day in the order they are eaten; sides are listed with ``sides(of:)``.
    func entries(on day: DayDate) -> [MealPlanEntry] {
        let order = MealType.allCases
        return entries.meals
            .filter { $0.date == day }
            .sorted { (order.firstIndex(of: $0.meal) ?? 0, $0.id) < (order.firstIndex(of: $1.meal) ?? 0, $1.id) }
    }

    /// Loads the entries of `week` and makes it the week later changes apply to.
    func load(_ week: Week) async {
        self.week = week
        await attempt {
            let loaded = try await session.send(MealPlanEndpoints.entries(from: week.start, to: week.end))
            if self.week == week {
                entries = loaded
            }
        }
        await loadReasons(of: week)
    }

    /// Plans a recipe or changes a planned entry, together with its sides; returns whether the server accepted it.
    func save(_ draft: PlanEntryDraft) async -> Bool {
        guard let recipe = draft.recipe else {
            return false
        }
        let day = DayDate(draft.date)
        return await change {
            try await saveSides(of: draft) {
                if let id = draft.entryID {
                    return try await session.send(MealPlanEndpoints.update(id: id, date: day, meal: draft.meal, recipeID: recipe.id, eaterIDs: draft.eaterIDs.sorted(), guests: draft.guests))
                }
                return try await session.send(MealPlanEndpoints.create(date: day, meal: draft.meal, recipeID: recipe.id, eaterIDs: draft.eaterIDs.sorted(), guests: draft.guests))
            }
        }
    }

    /// Moves an entry by `days`, which may be negative.
    func move(_ entry: MealPlanEntry, by days: Int) async {
        await change {
            _ = try await session.send(MealPlanEndpoints.update(id: entry.id, date: entry.date.adding(days: days), meal: entry.meal, recipeID: entry.recipe.id, servings: entry.servings))
        }
    }

    /// Moves every meal not cooked yet from `day` on by `days`, for when the household eats something else.
    func shift(from day: DayDate, by days: Int) async {
        await change {
            _ = try await session.send(MealPlanEndpoints.shift(from: day, days: days))
        }
    }

    /// The days of the loaded week that have an entry.
    var plannedDays: Set<DayDate> {
        Set(entries.map(\.date))
    }

    /// The slots of the loaded week that have an entry.
    var plannedSlots: Set<MealSlot> {
        Set(entries.map { MealSlot(date: $0.date, meal: $0.meal) })
    }

    /// Creates or refreshes the shopping list of the loaded week; returns whether the server accepted it.
    func createShoppingList() async -> Bool {
        guard let week else {
            return false
        }
        return await attempt {
            _ = try await session.send(ShoppingEndpoints.create(from: week.start, to: week.end))
        }
    }

    /// Marks an entry as cooked, or as not cooked if it already was.
    func toggleCooked(_ entry: MealPlanEntry) async {
        await attempt {
            let updated = try await session.send(MealPlanEndpoints.setCooked(!entry.isCooked, id: entry.id))
            if let index = entries.firstIndex(where: { $0.id == updated.id }) {
                entries[index] = updated
            }
        }
    }

    /// Says how the portion of an entry was for the signed-in user; choosing the same verdict again withdraws it.
    func judgePortion(of entry: MealPlanEntry, as verdict: PortionVerdict) async {
        guard let userID = session.user?.id else {
            return
        }
        let chosen = entry.verdict(of: userID) == verdict ? nil : verdict
        await change {
            _ = try await session.send(MealPlanEndpoints.setPortionVerdict(chosen, id: entry.id, userID: userID))
        }
    }

    /// The verdict of the signed-in user on the portion of an entry.
    func ownVerdict(on entry: MealPlanEntry) -> PortionVerdict? {
        entry.verdict(of: session.user?.id)
    }

    /// Removes an entry from the plan.
    func delete(_ entry: MealPlanEntry) async {
        await change {
            try await session.send(MealPlanEndpoints.delete(id: entry.id))
        }
    }

    /// Runs a change to the plan and reloads the week once the server accepted it.
    @discardableResult
    func change(_ work: () async throws -> Void) async -> Bool {
        let succeeded = await attempt(work)
        if succeeded, let week {
            await load(week)
        }
        return succeeded
    }

    /// Asks the server why the meals of `week` go together. Without a connection the plan simply shows no reasons.
    private func loadReasons(of week: Week) async {
        let loaded = try? await session.send(MealPlanEndpoints.reasons(from: week.start, to: week.end))
        if self.week == week {
            reasons = Dictionary((loaded ?? []).map { ($0.entryID, $0.reasons) }) { first, _ in first }
        }
    }
}
