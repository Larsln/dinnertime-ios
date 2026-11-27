import Foundation
import DinnertimeKit

/// The input for a new plan entry, or the changes to a planned one, with the sides served with it.
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
    /// The recipes served as sides with the meal.
    var sides: [RecipeSummary] = []
    /// The sides the changed entry has, to tell which ones the draft adds and removes.
    private let plannedSides: [MealPlanEntry]

    /// Starts a draft for `day`: every member eats, and guests fill up to the usual servings of the household.
    init(day: DayDate, servings: Int, members: [HouseholdMember]) {
        entryID = nil
        plannedSides = []
        date = day.date()
        eaterIDs = Set(members.map(\.id))
        guests = max(0, servings - members.count)
    }

    /// Starts a draft that changes a planned entry. An entry that names nobody counts all its servings as guests.
    init(entry: MealPlanEntry, sides: [MealPlanEntry] = []) {
        entryID = entry.id
        date = entry.date.date()
        meal = entry.meal
        eaterIDs = Set(entry.eaters?.map(\.userID) ?? [])
        guests = entry.eaters == nil ? entry.servings : entry.guests
        recipe = entry.recipe
        plannedSides = sides
        self.sides = sides.map(\.recipe)
    }

    /// Chooses the dish; sides it is not served with are taken out.
    mutating func choose(_ dish: RecipeSummary) {
        recipe = dish
        sides.removeAll { !$0.isSide(for: dish) }
    }

    /// The planned sides the draft no longer lists.
    var removedSides: [MealPlanEntry] {
        plannedSides.filter { side in !sides.contains { $0.id == side.recipe.id } }
    }

    /// The listed sides that are not planned yet.
    var addedSides: [RecipeSummary] {
        sides.filter { side in !plannedSides.contains { $0.recipe.id == side.id } }
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
