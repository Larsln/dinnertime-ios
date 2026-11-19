import Foundation

/// Reading and changing recipes.
public enum RecipeEndpoints {
    /// `GET /recipes`: one page of recipes, optionally filtered by title, courses, tags and favorites.
    ///
    /// A recipe has to be of one of the courses, suit one of the meal tags and carry all other tags.
    public static func list(
        search: String = "",
        tagIDs: [Int] = [],
        courses: [String] = [],
        favoritesOnly: Bool = false,
        page: Int = 1
    ) -> Endpoint<Page<RecipeSummary>> {
        var query = [URLQueryItem(name: "page", value: String(page))]
        if !search.isEmpty {
            query.append(URLQueryItem(name: "search", value: search))
        }
        query += courses.map { URLQueryItem(name: "courses[]", value: $0) }
        query += tagIDs.map { URLQueryItem(name: "tags[]", value: String($0)) }
        if favoritesOnly {
            query.append(URLQueryItem(name: "favorite", value: "1"))
        }
        return .plain(.get, "recipes", query: query)
    }

    /// `GET /recipes/{id}`: a complete recipe.
    public static func detail(id: Int) -> Endpoint<Recipe> {
        .resource(.get, "recipes/\(id)")
    }

    /// `POST /recipes`: creates a recipe.
    public static func create(_ input: RecipeInput) -> Endpoint<Recipe> {
        .resource(.post, "recipes", body: input)
    }

    /// `PATCH /recipes/{id}`: replaces the content of a recipe.
    public static func update(id: Int, _ input: RecipeInput) -> Endpoint<Recipe> {
        .resource(.patch, "recipes/\(id)", body: input)
    }

    /// `DELETE /recipes/{id}`: deletes a recipe together with its cover image.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "recipes/\(id)")
    }

    /// `POST /recipes/{id}/cover`: replaces the cover image with a JPEG.
    public static func uploadCover(id: Int, jpeg: Data) -> Endpoint<Recipe> {
        .upload("recipes/\(id)/cover", form: MultipartForm(field: "image", fileName: "cover.jpg", mimeType: "image/jpeg", data: jpeg))
    }
}
