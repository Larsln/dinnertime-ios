import DinnertimeKit
import SwiftUI

/// A recipe on narrow screens: one list with the header at the top and the ingredients and the method on two segments.
struct RecipeCompactLayout: View {
    @Bindable var model: RecipeDetailModel

    var body: some View {
        PaperList {
            Section {
                RecipeHeader(model: model)
            }
            if let recipe = model.recipe {
                content(of: recipe)
            } else if model.errorMessage == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func content(of recipe: Recipe) -> some View {
        Section {
            Picker("Content", selection: $model.segment) {
                Text("Ingredients")
                    .tag(RecipeDetailModel.Segment.ingredients)
                Text("Method")
                    .tag(RecipeDetailModel.Segment.method)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        switch model.segment {
        case .ingredients:
            RecipeIngredientList(recipe: recipe, model: model)
        case .method:
            RecipeMethodList(recipe: recipe, scale: model.scale)
        }
        if let url = recipe.sourceURL {
            Section {
                Link(destination: url) {
                    Label("View original", systemImage: "safari")
                }
            }
        }
    }
}
