import Foundation

/// Recipes and the tags to filter them by.
public enum RecipeEndpoints {
    /// `GET /recipes`: one page of recipes, optionally filtered by title and tag.
    public static func list(search: String = "", tagID: Int? = nil, page: Int = 1) -> Endpoint<Page<RecipeSummary>> {
        var query = [URLQueryItem(name: "page", value: String(page))]
        if !search.isEmpty {
            query.append(URLQueryItem(name: "search", value: search))
        }
        if let tagID {
            query.append(URLQueryItem(name: "tag", value: String(tagID)))
        }
        return .plain(.get, "recipes", query: query)
    }

    /// `GET /recipes/{id}`: a complete recipe.
    public static func detail(id: Int) -> Endpoint<Recipe> {
        .resource(.get, "recipes/\(id)")
    }

    /// `GET /tags`: all tags in the requested language.
    public static var tags: Endpoint<[Tag]> {
        .resource(.get, "tags")
    }
}
