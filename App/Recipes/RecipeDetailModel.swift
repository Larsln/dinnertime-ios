import MealplannerKit
import Observation

/// Loads one recipe and scales its ingredients to the wanted servings.
@MainActor
@Observable
final class RecipeDetailModel: ErrorReporting {
    static let servingsRange = 1...100

    var errorMessage: String?
    /// Servings the ingredient amounts are shown for.
    var servings: Int
    private(set) var recipe: Recipe?

    let summary: RecipeSummary
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
            recipe = try await session.send(RecipeEndpoints.detail(id: summary.id))
        }
    }
}
