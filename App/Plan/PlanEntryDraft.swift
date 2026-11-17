import Foundation
import MealplannerKit

/// The input for a new plan entry.
struct PlanEntryDraft: Identifiable {
    static let servingsRange = 1...50

    let id = UUID()
    var date: Date
    var meal = MealType.dinner
    var servings = 2
    var recipe: RecipeSummary?

    init(day: DayDate) {
        date = day.date()
    }
}
