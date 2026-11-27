import Foundation
import DinnertimeKit

/// The input for a new plan entry, or the changes to a planned one.
struct PlanEntryDraft: Identifiable {
    static let guestRange = 0...50

    let id = UUID()
    /// The entry the draft changes; `nil` for a new one.
    let entryID: Int?
    var date: Date
    var meal = MealType.dinner
    /// Members of the household who eat.
    var eaterIDs: Set<Int>
    /// People who eat besides the members; each counts with a standard portion.
    var guests: Int
    var recipe: RecipeSummary?

    /// Starts a draft for `day`: every member eats, and guests fill up to the usual servings of the household.
    init(day: DayDate, servings: Int, members: [HouseholdMember]) {
        entryID = nil
        date = day.date()
        eaterIDs = Set(members.map(\.id))
        guests = max(0, servings - members.count)
    }

    /// Starts a draft that changes a planned entry. An entry that names nobody counts all its servings as guests.
    init(entry: MealPlanEntry) {
        entryID = entry.id
        date = entry.date.date()
        meal = entry.meal
        eaterIDs = Set(entry.eaters?.map(\.userID) ?? [])
        guests = entry.eaters == nil ? entry.servings : entry.guests
        recipe = entry.recipe
    }

    /// Whether the draft changes a planned entry rather than adding one.
    var isChange: Bool {
        entryID != nil
    }

    /// Number of people who eat.
    var headcount: Int {
        eaterIDs.count + guests
    }

    /// Whether the draft names a recipe and somebody who eats it.
    var isComplete: Bool {
        recipe != nil && headcount > 0
    }
}
