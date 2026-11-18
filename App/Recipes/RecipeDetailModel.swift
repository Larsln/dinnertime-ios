import MealplannerKit
import Observation

/// Loads one recipe, scales its ingredients to the wanted servings and keeps the marks of the user.
@MainActor
@Observable
final class RecipeDetailModel: ErrorReporting {
    /// The two parts of the content the view switches between.
    enum Segment: Hashable {
        case ingredients, method
    }

    static let servingsRange = 1...100

    var errorMessage: String?
    /// The part of the content that is shown.
    var segment = Segment.ingredients
    /// Servings the ingredient amounts are shown for.
    var servings: Int
    /// What is known about the recipe before and after it is loaded, including the marks of the user.
    private(set) var summary: RecipeSummary
    private(set) var recipe: Recipe?
    /// Counts the rating and favorite changes, so that only the answer to the latest one is taken over.
    private var markCount = 0

    private let session: AppSession

    init(session: AppSession, summary: RecipeSummary) {
        self.session = session
        self.summary = summary
        servings = summary.servings ?? 1
    }

    /// Whether the recipe states servings to scale from.
    var canScale: Bool {
        summary.servings != nil
    }

    /// Ratio of wanted to stated servings.
    var scale: Double {
        summary.servings.map { Double(servings) / Double($0) } ?? 1
    }

    /// Loads the complete recipe.
    func load() async {
        await attempt {
            show(try await session.send(RecipeEndpoints.detail(id: summary.id)))
        }
    }

    /// Shows the recipe as the server holds it and returns to its stated servings if they changed.
    func show(_ recipe: Recipe) {
        if recipe.summary.servings != summary.servings {
            servings = recipe.summary.servings ?? 1
        }
        self.recipe = recipe
        summary = recipe.summary
    }

    /// Sets the rating of the user; `nil` withdraws it.
    func rate(_ rating: Int?) async {
        await mark(RecipeMarkEndpoints.rate(rating, id: summary.id)) { $0.rating = rating }
    }

    /// Marks the recipe as a favorite or removes the mark.
    func toggleFavorite() async {
        let favorite = !summary.isFavorite
        await mark(RecipeMarkEndpoints.setFavorite(favorite, id: summary.id)) { $0.isFavorite = favorite }
    }

    /// Deletes the recipe; returns whether the server accepted it.
    func delete() async -> Bool {
        await attempt {
            try await session.send(RecipeEndpoints.delete(id: summary.id))
        }
    }

    /// Applies a change at once and undoes it if the server rejects it; a newer change keeps what it set.
    private func mark(_ endpoint: Endpoint<RecipeSummary>, optimistically change: (inout RecipeSummary) -> Void) async {
        markCount += 1
        let number = markCount
        let previous = summary
        change(&summary)
        do {
            let answer = try await session.send(endpoint)
            if number == markCount {
                summary = answer
            }
        } catch {
            if number == markCount {
                summary = previous
            }
            report(error)
        }
    }
}
