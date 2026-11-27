import Foundation
@testable import DinnertimeKit

/// A small household for the tests of sides: a schnitzel served with potatoes or rice, a curry served with rice,
/// sides of three kinds and the schnitzel planned once.
enum SideSupport {
    static let day = DayDate(year: 2026, month: 11, day: 17)
    static let schnitzel = 1
    static let fries = 2
    static let rice = 3
    static let noodles = 4
    static let curry = 5
    static let bakedPotatoes = 6
    /// The planned schnitzel.
    static let meal = 10

    static func recipe(_ id: Int, _ title: String, kind: String? = nil, options: [String] = []) -> [String: Any] {
        OfflineSupport.recipe(id: id, title: title).merging(["side_kind": kind ?? NSNull(), "side_options": options]) { _, new in new }
    }

    static var recipes: [[String: Any]] {
        [
            recipe(schnitzel, "Schnitzel", options: ["potato", "rice"]),
            recipe(fries, "Fritten", kind: "potato"),
            recipe(rice, "Reis", kind: "rice"),
            recipe(noodles, "Butternudeln", kind: "pasta"),
            recipe(curry, "Curry", options: ["rice"]),
            recipe(bakedPotatoes, "Ofenkartoffeln", kind: "potato"),
        ]
    }

    /// A plan entry as the server sends it; `parent` makes it a side.
    static func entry(_ id: Int, recipe recipeID: Int, date: DayDate = day, parent: Int? = nil, extra: [String: Any] = [:]) -> [String: Any] {
        let record: [String: Any] = [
            "id": id, "parent_id": parent ?? NSNull(), "date": date.description, "meal": "dinner", "servings": 2,
            "cooked_at": NSNull(), "recipe": recipes.first { $0["id"] as? Int == recipeID } ?? [:],
        ]
        return record.merging(extra) { _, new in new }
    }

    /// A store that holds the recipes and the given entries, the planned schnitzel by default.
    static func store(entries: [[String: Any]]? = nil) async throws -> OfflineStore {
        let store = OfflineStore(directory: OfflineSupport.directory())
        let planned = entries ?? [entry(meal, recipe: schnitzel)]
        _ = try await store.applySync(OfflineSupport.page(version: 1, changed: ["recipes": recipes, "meal_plan_entries": planned]))
        return store
    }

    /// The entries around the day of the tests.
    static func plan(_ store: OfflineStore) async throws -> [MealPlanEntry] {
        guard let answer = try await store.answer(MealPlanEndpoints.entries(from: day.adding(days: -14), to: day.adding(days: 14))) else {
            throw APIError.invalidResponse
        }
        return answer.response
    }

    /// Serves a side with an entry on the copy.
    @discardableResult
    static func serve(_ recipeID: Int, with entryID: Int = meal, in store: OfflineStore) async throws -> MealPlanEntry {
        guard let answer = try await store.answer(MealPlanEndpoints.addSide(recipeID: recipeID, to: entryID)) else {
            throw APIError.invalidResponse
        }
        return answer.response
    }
}
