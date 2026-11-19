import DinnertimeKit
import SwiftUI

/// The recipe collection with search, filters and access to the editor and the imports; notifications about imports lead here.
struct RecipeListView: View {
    let session: AppSession

    @State private var model: RecipeListModel
    @State private var path: [RecipeSummary] = []
    @State private var showsImports = false
    @State private var showsEditor = false
    @State private var router = ImportRouter.shared
    @State private var permission = NotificationPermission()

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: RecipeListModel(session: session))
    }

    var body: some View {
        NavigationStack(path: $path) {
            RecipeSearchList(model: model) { recipe in
                NavigationLink(value: recipe) {
                    RecipeRow(recipe: recipe)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if permission.isOffered {
                    NotificationOffer(permission: permission)
                }
            }
            .navigationTitle("Recipes")
            .navigationDestination(for: RecipeSummary.self) { recipe in
                RecipeDetailView(session: session, summary: recipe, onUpdate: model.replace) {
                    model.remove(id: recipe.id)
                }
            }
            .settingsToolbar(session: session)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    RecipeFilterMenu(model: model)
                    Button("Import", systemImage: "square.and.arrow.down") {
                        showsImports = true
                    }
                    Button("New recipe", systemImage: "plus") {
                        showsEditor = true
                    }
                }
            }
            .sheet(isPresented: $showsImports, onDismiss: reload) {
                ImportsView(session: session)
            }
            .sheet(isPresented: $showsEditor) {
                RecipeEditorView(session: session, recipe: nil, onSave: open)
            }
            .task {
                await permission.refresh()
                await model.loadFilters()
            }
            .reloadsOnChange(of: .recipes) {
                await model.reload()
            }
            .task(id: router.destination) {
                await follow(router.destination)
            }
        }
    }

    /// Shows what a tapped notification asks for: the imported recipe, or the imports when there is none.
    private func follow(_ destination: ImportDestination?) async {
        guard let destination else {
            return
        }
        router.destination = nil
        if case let .recipe(importID) = destination, let recipe = await model.recipe(ofImport: importID) {
            path = [recipe]
        } else {
            showsImports = true
        }
    }

    private func open(_ recipe: Recipe) {
        path.append(recipe.summary)
        reload()
    }

    private func reload() {
        Task {
            await model.reload()
        }
    }
}
