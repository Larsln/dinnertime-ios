import Foundation

/// Reading and changing recipes.
public enum RecipeEndpoints {
    /// `GET /recipes`: one page of recipes, optionally filtered by title, tag, course and favorites.
    public static func list(
        search: String = "",
        tagID: Int? = nil,
        course: String? = nil,
        favoritesOnly: Bool = false,
        page: Int = 1
    ) -> Endpoint<Page<RecipeSummary>> {
        var query = [URLQueryItem(name: "page", value: String(page))]
        if !search.isEmpty {
            query.append(URLQueryItem(name: "search", value: search))
        }
        if let tagID {
            query.append(URLQueryItem(name: "tag", value: String(tagID)))
        }
        if let course {
            query.append(URLQueryItem(name: "course", value: course))
        }
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
