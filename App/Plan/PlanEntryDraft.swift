import Foundation
import DinnertimeKit

/// The input for a new plan entry, or the changes to a planned one.
struct PlanEntryDraft: Identifiable {
    static let servingsRange = 1...50

    let id = UUID()
    /// The entry the draft changes; `nil` for a new one.
    let entryID: Int?
    var date: Date
    var meal = MealType.dinner
    var servings: Int
    var recipe: RecipeSummary?

    /// Starts a draft for `day` with the usual servings of the household.
    init(day: DayDate, servings: Int) {
        entryID = nil
        date = day.date()
        self.servings = servings
    }

    /// Starts a draft that changes a planned entry.
    init(entry: MealPlanEntry) {
        entryID = entry.id
        date = entry.date.date()
        meal = entry.meal
        servings = entry.servings
        recipe = entry.recipe
    }

    /// Whether the draft changes a planned entry rather than adding one.
    var isChange: Bool {
        entryID != nil
    }
}
