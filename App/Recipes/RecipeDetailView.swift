import MealplannerKit
import SwiftUI

/// A recipe with its rating at the top, its ingredients and method on two segments and the ways to change it.
struct RecipeDetailView: View {
    let session: AppSession
    let onUpdate: (RecipeSummary) -> Void
    let onDelete: () -> Void

    @State private var model: RecipeDetailModel
    @State private var showsEditor = false
    @State private var confirmsDeletion = false
    @Environment(\.dismiss) private var dismiss
    @Environment(HouseholdStore.self) private var household

    init(
        session: AppSession,
        summary: RecipeSummary,
        onUpdate: @escaping (RecipeSummary) -> Void = { _ in },
        onDelete: @escaping () -> Void = {}
    ) {
        self.session = session
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _model = State(initialValue: RecipeDetailModel(session: session, summary: summary))
    }

    var body: some View {
        List {
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
        .navigationTitle(Text(verbatim: model.summary.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            RecipeDetailToolbar(model: model, showsEditor: $showsEditor, confirmsDeletion: $confirmsDeletion)
        }
        .sheet(isPresented: $showsEditor) {
            RecipeEditorView(session: session, recipe: model.recipe, onSave: model.show)
        }
        .confirmationDialog("Delete recipe", isPresented: $confirmsDeletion, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
        } message: {
            Text("“\(model.summary.title)” will be deleted permanently.")
        }
        .task {
            model.open(withServings: household.defaultServings)
            await model.load()
        }
        .onChange(of: model.summary) { _, summary in
            onUpdate(summary)
        }
        .errorAlert($model.errorMessage)
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
            RecipeMethodList(recipe: recipe)
        }
        if let url = recipe.sourceURL {
            Section {
                Link(destination: url) {
                    Label("View original", systemImage: "safari")
                }
            }
        }
    }

    private func delete() {
        Task {
            if await model.delete() {
                onDelete()
                dismiss()
            }
        }
    }
}
