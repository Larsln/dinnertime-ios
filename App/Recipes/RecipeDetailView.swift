import MealplannerKit
import SwiftUI

/// A recipe with scalable ingredients, steps, tools and the link to its source.
struct RecipeDetailView: View {
    @State private var model: RecipeDetailModel

    init(session: AppSession, summary: RecipeSummary) {
        _model = State(initialValue: RecipeDetailModel(session: session, summary: summary))
    }

    var body: some View {
        List {
            Section {
                RecipeHeader(recipe: model.recipe?.summary ?? model.summary)
            }
            if let recipe = model.recipe {
                ingredients(of: recipe)
                steps(of: recipe)
                tools(of: recipe)
                source(of: recipe)
            } else if model.errorMessage == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(Text(verbatim: model.summary.title))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.load()
        }
        .errorAlert($model.errorMessage)
    }

    @ViewBuilder
    private func ingredients(of recipe: Recipe) -> some View {
        if model.canScale {
            Section("Ingredients") {
                Stepper("Servings: \(model.servings)", value: $model.servings, in: RecipeDetailModel.servingsRange)
            }
        }
        ForEach(recipe.ingredientGroups) { group in
            Section {
                ForEach(group.ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient, scale: model.scale)
                }
            } header: {
                if let title = group.title {
                    Text(verbatim: title)
                } else if !model.canScale, group.id == 0 {
                    Text("Ingredients")
                }
            }
        }
    }

    @ViewBuilder
    private func steps(of recipe: Recipe) -> some View {
        if !recipe.steps.isEmpty {
            Section("Steps") {
                ForEach(recipe.steps) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        if let title = step.title {
                            Text(verbatim: title)
                                .font(.headline)
                        }
                        Text(verbatim: "\(step.position). \(step.text)")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tools(of recipe: Recipe) -> some View {
        if !recipe.tools.isEmpty {
            Section("Tools") {
                ForEach(recipe.tools) { tool in
                    Text(verbatim: tool.name)
                }
            }
        }
    }

    @ViewBuilder
    private func source(of recipe: Recipe) -> some View {
        if let url = recipe.sourceURL {
            Section {
                Link(destination: url) {
                    Label("View original", systemImage: "safari")
                }
            }
        }
    }
}
