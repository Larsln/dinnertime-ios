import DinnertimeKit
import SwiftUI

/// A recipe on wide screens: a panel with the cover and the header at the top and, below them,
/// the ingredients and the method side by side, so that both stay in view while cooking.
///
/// Where the panel is too narrow for two columns, the method follows the ingredients.
struct RecipeWideLayout<Actions: View>: View {
    private static var coverHeight: CGFloat { 200 }
    private static var columnWeights: [CGFloat] { [2, 3] }
    private static var columnSpacing: CGFloat { 28 }

    @Bindable var model: RecipeDetailModel
    /// The controls that change the recipe, where no navigation bar carries them.
    @ViewBuilder let actions: Actions

    @State private var fitsColumns = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if model.summary.coverURL != nil {
                    Color.accentSoft
                        .frame(height: Self.coverHeight)
                        .overlay {
                            CoverImage(url: model.summary.coverURL)
                        }
                        .clipped()
                }
                VStack(alignment: .leading, spacing: 24) {
                    RecipeWideHeader(model: model) {
                        actions
                    }
                    if let recipe = model.recipe {
                        content(of: recipe)
                    } else if model.errorMessage == nil {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(24)
            }
        }
        .onGeometryChange(for: Bool.self) { proxy in
            proxy.size.width >= ReadableMetrics.recipeColumns
        } action: { fits in
            fitsColumns = fits
        }
        .panel()
        .frame(maxWidth: ReadableMetrics.recipe)
        .padding(ReadableMetrics.panelMargin)
        .paperScreen()
    }

    @ViewBuilder
    private func content(of recipe: Recipe) -> some View {
        let layout = fitsColumns
            ? AnyLayout(WeightedColumns(weights: Self.columnWeights, spacing: Self.columnSpacing))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: Self.columnSpacing))
        layout {
            RecipeIngredientColumn(recipe: recipe, model: model)
            RecipeMethodColumn(recipe: recipe, scale: model.scale)
        }
        if let url = recipe.sourceURL {
            Link(destination: url) {
                Label("View original", systemImage: "safari")
            }
        }
    }
}
