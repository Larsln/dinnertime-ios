import Foundation
import DinnertimeKit

/// The input for a new plan entry.
struct PlanEntryDraft: Identifiable {
    static let servingsRange = 1...50

    let id = UUID()
    var date: Date
    var meal = MealType.dinner
    var servings: Int
    var recipe: RecipeSummary?

    /// Starts a draft for `day` with the usual servings of the household.
    init(day: DayDate, servings: Int) {
        date = day.date()
        self.servings = servings
    }
}
