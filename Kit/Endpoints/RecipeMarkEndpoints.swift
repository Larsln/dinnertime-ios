import Foundation

/// The rating and favorite mark the signed-in user gives a recipe.
public enum RecipeMarkEndpoints {
    private struct RatingBody: Encodable {
        let rating: Int?

        private enum CodingKeys: String, CodingKey {
            case rating
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(rating, forKey: .rating)
        }
    }

    private struct FavoriteBody: Encodable {
        let favorite: Bool
    }

    /// `PUT /recipes/{id}/rating`: rates a recipe within ``RecipeSummary/ratingRange``; `nil` withdraws the rating.
    public static func rate(_ rating: Int?, id: Int) -> Endpoint<RecipeSummary> {
        .resource(.put, "recipes/\(id)/rating", body: RatingBody(rating: rating))
    }

    /// `PUT /recipes/{id}/favorite`: marks a recipe as a favorite or removes the mark.
    public static func setFavorite(_ favorite: Bool, id: Int) -> Endpoint<RecipeSummary> {
        .resource(.put, "recipes/\(id)/favorite", body: FavoriteBody(favorite: favorite))
    }
}
