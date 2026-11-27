import DinnertimeKit
import Observation

/// Loads one recipe, scales its ingredients to the wanted servings and keeps the marks of the user.
@MainActor
@Observable
final class RecipeDetailModel: ErrorReporting {
    /// The two parts of the content the view switches between.
    enum Segment: Hashable {
        case ingredients, method
    }

    static let servingsRange = 0.5...100.0

    var errorMessage: String?
    /// The part of the content that is shown.
    var segment = Segment.ingredients
    /// Servings the ingredient amounts are shown for.
    var servings: Double
    /// What is known about the recipe before and after it is loaded, including the marks of the user.
    private(set) var summary: RecipeSummary
    private(set) var recipe: Recipe?
    /// Counts the rating and favorite changes, so that only the answer to the latest one is taken over.
    private var markCount = 0

    /// Servings a recipe opens with: those of the plan entry it was opened from, or the usual number of the household once the view passed it on.
    private var defaultServings: Double?

    private let session: AppSession

    /// - Parameter plannedServings: Servings of the plan entry the recipe is opened from; they take the place of the usual number of the household.
    init(session: AppSession, summary: RecipeSummary, plannedServings: Double? = nil) {
        self.session = session
        self.summary = summary
        defaultServings = plannedServings
        servings = summary.servings.map { plannedServings ?? Double($0) } ?? 1
    }

    /// Shows a recipe that states servings scaled to the usual number of the household.
    ///
    /// Only the first call counts, so that the choice of the user survives when the view appears again,
    /// and none counts for a recipe opened with the servings of a plan entry.
    func open(withServings servings: Int) {
        guard defaultServings == nil else {
            return
        }
        defaultServings = Double(servings)
        self.servings = initialServings(for: summary)
    }

    /// The servings as a number: whole ones without decimals, others with up to two.
    var servingsText: String {
        servings.formatted(.number.precision(.fractionLength(0...2)))
    }

    /// Whether the recipe states servings to scale from.
    var canScale: Bool {
        summary.servings != nil
    }

    /// Ratio of wanted to stated servings.
    var scale: Double {
        summary.servings.map { servings / Double($0) } ?? 1
    }

    /// Loads the complete recipe.
    func load() async {
        await attempt {
            show(try await session.send(RecipeEndpoints.detail(id: summary.id)))
        }
    }

    /// Shows the recipe as the server holds it and returns to the initial servings if the stated ones changed.
    func show(_ recipe: Recipe) {
        if recipe.summary.servings != summary.servings {
            servings = initialServings(for: recipe.summary)
        }
        self.recipe = recipe
        summary = recipe.summary
    }

    /// A recipe that states servings opens with the default; one without cannot be scaled.
    private func initialServings(for summary: RecipeSummary) -> Double {
        summary.servings.map { defaultServings ?? Double($0) } ?? 1
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
