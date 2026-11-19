import DinnertimeKit
import SwiftUI

/// The recipe collection with search, filters and access to the editor and the imports, below what matters today:
/// the next meal to cook and the way to decide tonight's dinner. Notifications about imports lead here.
struct RecipeListView: View {
    let session: AppSession

    @State private var model: RecipeListModel
    @State private var today: TodayModel
    @State private var path = NavigationPath()
    /// The recipe shown next to the list on wide screens.
    @State private var selection: RecipeSelection?
    @State private var showsDinner = false
    @State private var showsImports = false
    @State private var showsEditor = false
    @State private var router = ImportRouter.shared
    @State private var permission = NotificationPermission()
    @Environment(\.horizontalSizeClass) private var sizeClass

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: RecipeListModel(session: session))
        _today = State(initialValue: TodayModel(session: session))
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if sizeClass == .regular {
                    RecipeBrowser(session: session, model: model, today: today, permission: permission, selection: $selection) {
                        showsDinner = true
                    }
                } else {
                    list
                        .notificationOffer(permission)
                }
            }
            .navigationTitle("Recipes")
            .navigationBarTitleDisplayMode(sizeClass == .regular ? .inline : .automatic)
            .navigationDestination(for: RecipeSummary.self) { recipe in
                RecipeDetailView(session: session, summary: recipe, onUpdate: model.replace) {
                    model.remove(id: recipe.id)
                }
            }
            .navigationDestination(for: PlannedRecipe.self) { planned in
                RecipeDetailView(session: session, summary: planned.recipe, plannedServings: planned.servings, onUpdate: model.replace) {
                    model.remove(id: planned.recipe.id)
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
            .sheet(isPresented: $showsDinner) {
                DinnerRoundView(model: today.dinner) { entry in
                    show(PlannedRecipe(entry))
                }
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
            .keepsTodayCurrent(today)
            .task(id: router.destination) {
                await follow(router.destination)
            }
        }
    }

    /// The recipes below what matters today, each leading to a screen of its own.
    private var list: some View {
        RecipeSearchList(model: model) {
            TodayPanel(model: today) { planned in
                show(planned)
            } onDecide: {
                showsDinner = true
            }
        } row: { recipe in
            NavigationLink(value: recipe) {
                RecipeRow(recipe: recipe)
            }
        }
    }

    /// Opens a recipe with planned servings: next to the list on wide screens, else on a screen of its own.
    private func show(_ planned: PlannedRecipe) {
        if sizeClass == .regular {
            selection = RecipeSelection(planned)
        } else {
            path.append(planned)
        }
    }

    /// Opens a recipe: next to the list on wide screens, else on a screen of its own.
    private func show(_ recipe: RecipeSummary, replacingPath: Bool = false) {
        if sizeClass == .regular {
            selection = RecipeSelection(recipe: recipe)
        } else if replacingPath {
            path = NavigationPath([recipe])
        } else {
            path.append(recipe)
        }
    }

    /// Shows what a tapped notification asks for: the imported recipe, or the imports when there is none.
    private func follow(_ destination: ImportDestination?) async {
        guard let destination else {
            return
        }
        router.destination = nil
        if case let .recipe(importID) = destination, let recipe = await model.recipe(ofImport: importID) {
            show(recipe, replacingPath: true)
        } else {
            showsImports = true
        }
    }

    private func open(_ recipe: Recipe) {
        show(recipe.summary)
        reload()
    }

    private func reload() {
        Task {
            await model.reload()
        }
    }
}
