import MealplannerKit
import SwiftUI

/// The recipe collection with search, tag filter and access to the imports.
struct RecipeListView: View {
    let session: AppSession

    @State private var model: RecipeListModel
    @State private var showsImports = false

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: RecipeListModel(session: session))
    }

    var body: some View {
        NavigationStack {
            RecipeSearchList(model: model) { recipe in
                NavigationLink(value: recipe) {
                    RecipeRow(recipe: recipe)
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: RecipeSummary.self) { recipe in
                RecipeDetailView(session: session, summary: recipe)
            }
            .settingsToolbar(session: session)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    TagFilterMenu(model: model)
                    Button("Import", systemImage: "square.and.arrow.down") {
                        showsImports = true
                    }
                }
            }
            .sheet(isPresented: $showsImports, onDismiss: reload) {
                ImportsView(session: session)
            }
            .task {
                await model.loadTags()
            }
        }
    }

    private func reload() {
        Task {
            await model.reload()
        }
    }
}
