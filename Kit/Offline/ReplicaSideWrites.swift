import Foundation

/// The sides of planned meals, kept with their meal on the local copy the way the server keeps them.
extension Replica {
    /// The recipes that may be served with the dish with `id`, those served with it most recently first, then by title.
    func sideOptions(forRecipe id: Int?) throws -> [JSONObject] {
        let dish = try existing(.recipes, id)
        let meals = Set(all(.mealPlanEntries).filter { ($0["recipe"] as? JSONObject)?.recordID == dish.recordID }.compactMap(\.recordID))
        var lastServed: [Int: String] = [:]
        for side in all(.mealPlanEntries) where (side["parent_id"] as? Int).map(meals.contains) == true {
            if let recipeID = (side["recipe"] as? JSONObject)?.recordID, let date = side["date"] as? String {
                lastServed[recipeID] = max(lastServed[recipeID] ?? "", date)
            }
        }
        let found = all(.recipes).filter { $0.recordID != dish.recordID && accepts(dish, $0) }
        return sorted(found, by: "title")
            .enumerated()
            .sorted { first, second in
                let served = (lastServed[first.element.recordID ?? 0] ?? "", lastServed[second.element.recordID ?? 0] ?? "")
                return served.0 == served.1 ? first.offset < second.offset : served.0 > served.1
            }
            .map { shownRecipe($0.element) }
    }

    /// The sides served with the meal with `id`.
    func sides(ofEntry id: Int?) -> [JSONObject] {
        all(.mealPlanEntries).filter { id != nil && $0["parent_id"] as? Int == id }
    }

    /// Serves a side with a planned meal: the side eats on the day, at the meal and with the people of its meal.
    ///
    /// Every member starts with a standard portion of the side; the server corrects that with the next sync.
    /// Throws the validation failure of the server when the dish is not served with sides of that kind.
    mutating func addSide(toEntry id: Int?, from body: JSONObject) throws -> JSONObject {
        let meal = try existing(.mealPlanEntries, id)
        let recipe = try existing(.recipes, body["recipe_id"] as? Int)
        let dish = current(.recipes, meal["recipe"]) as? JSONObject ?? [:]
        guard meal["parent_id"] as? Int == nil, accepts(dish, recipe) else {
            let message = String(localized: "This side is not served with this dish.", bundle: .kit)
            throw APIError.validation(message: message, fields: ["recipe_id": [message]])
        }
        var side: JSONObject = [
            "id": makeTemporaryID(),
            "parent_id": meal.recordID ?? 0,
            "cooked_at": meal["cooked_at"] ?? NSNull(),
            "portion_feedback": [JSONObject](),
            "recipe": recipe,
        ]
        seat(&side, like: meal)
        put(.mealPlanEntries, side)
        return side
    }

    /// Applies what changed on an entry to what hangs together with it.
    ///
    /// A side that moved to another day or meal becomes a meal of its own. The sides of a meal follow its day, meal,
    /// eaters and cooked state, and those a new dish is not served with are dropped.
    mutating func keepSides(with entry: inout JSONObject, before: JSONObject) {
        let snapshot = entry
        let differs: (String) -> Bool = { key in
            !(snapshot[key] as? NSObject ?? NSNull()).isEqual(before[key] as? NSObject ?? NSNull())
        }
        guard entry["parent_id"] as? Int == nil else {
            if differs("date") || differs("meal") {
                entry["parent_id"] = NSNull()
            }
            return
        }
        let dish = current(.recipes, entry["recipe"]) as? JSONObject ?? [:]
        let changesRecipe = (before["recipe"] as? JSONObject)?.recordID != dish.recordID
        let changesSeats = ["date", "meal", "servings", "eaters", "guests"].contains(where: differs)
        for var side in sides(ofEntry: entry.recordID) {
            if changesRecipe, !accepts(dish, current(.recipes, side["recipe"]) as? JSONObject ?? [:]) {
                remove(.mealPlanEntries, side.recordID ?? 0)
                continue
            }
            if changesSeats {
                seat(&side, like: entry)
            }
            if differs("cooked_at") {
                side["cooked_at"] = entry["cooked_at"] ?? NSNull()
            }
            put(.mealPlanEntries, side)
        }
    }

    /// Removes an entry from the plan together with its sides.
    mutating func removeEntry(_ id: Int) {
        for side in sides(ofEntry: id) {
            remove(.mealPlanEntries, side.recordID ?? 0)
        }
        remove(.mealPlanEntries, id)
    }

    /// Whether a dish is served with sides of the kind of a recipe.
    private func accepts(_ dish: JSONObject, _ side: JSONObject) -> Bool {
        (side["side_kind"] as? String).map((dish["side_options"] as? [String] ?? []).contains) ?? false
    }

    /// Gives a side the day, the meal and the eaters of its meal.
    private func seat(_ side: inout JSONObject, like meal: JSONObject) {
        side["date"] = meal["date"] ?? ""
        side["meal"] = meal["meal"] ?? ""
        if let eaters = meal["eaters"] as? [JSONObject] {
            seat(&side, as: ["eater_ids": eaters.compactMap { ($0["user_id"] as? NSNumber)?.intValue }, "guests": meal["guests"] ?? 0])
        } else {
            side["servings"] = meal["servings"] ?? 1
            side["eaters"] = NSNull()
            side["guests"] = 0
            side["portions"] = meal["servings"] ?? 1
        }
    }
}
