import DinnertimeKit
import Observation

/// Loads and changes the meal plan of one week.
@MainActor
@Observable
final class PlanModel: ErrorReporting {
    var errorMessage: String?
    private(set) var entries: [MealPlanEntry] = []

    private var week: Week?
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Entries of one day in the order of the meals.
    func entries(on day: DayDate) -> [MealPlanEntry] {
        let order = MealType.allCases
        return entries
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
    }

    /// Plans a recipe; returns whether the server accepted it.
    func add(_ draft: PlanEntryDraft) async -> Bool {
        guard let recipe = draft.recipe else {
            return false
        }
        return await attempt {
            let endpoint = MealPlanEndpoints.create(date: DayDate(draft.date), meal: draft.meal, recipeID: recipe.id, servings: draft.servings)
            insert([try await session.send(endpoint)])
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

    /// Removes an entry from the plan.
    func delete(_ entry: MealPlanEntry) async {
        await attempt {
            try await session.send(MealPlanEndpoints.delete(id: entry.id))
            entries.removeAll { $0.id == entry.id }
        }
    }

    private func insert(_ added: [MealPlanEntry]) {
        guard let week else {
            return
        }
        entries += added.filter { week.contains($0.date) }
    }
}
