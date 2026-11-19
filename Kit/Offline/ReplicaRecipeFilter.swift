import Foundation

/// What the list of recipes is narrowed by.
struct RecipeFilter {
    var search: String?
    /// Meal tags and other tags alike.
    var tagIDs: [Int] = []
    /// Keys of the courses.
    var courses: [String] = []
    var favoritesOnly = false
}

/// The recipe list as the server filters it.
extension Replica {
    /// Recipes that match a filter, sorted by title.
    ///
    /// A recipe has to be of one of the courses, suit one of the meal tags and carry all other tags.
    func recipes(matching filter: RecipeFilter) -> [JSONObject] {
        let meals = filter.tagIDs.filter(isMeal)
        let properties = filter.tagIDs.filter { !isMeal($0) }
        let found = all(.recipes).filter { recipe in
            let carried = Set((recipe["tags"] as? [JSONObject] ?? []).compactMap(\.recordID))
            return matches(recipe["title"] as? String, filter.search)
                && (filter.courses.isEmpty || (recipe["course"] as? String).map(filter.courses.contains) == true)
                && (meals.isEmpty || meals.contains(where: carried.contains))
                && properties.allSatisfy(carried.contains)
                && (!filter.favoritesOnly || recipe["is_favorite"] as? Bool == true)
        }
        return sorted(found, by: "title").map(shownRecipe)
    }

    /// Whether a tag names a meal, of which a recipe has to suit only one.
    private func isMeal(_ tagID: Int) -> Bool {
        record(.tags, tagID)?["type"] as? String == Tag.Kind.meal.rawValue
    }
}
