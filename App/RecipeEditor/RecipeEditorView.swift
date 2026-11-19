import DinnertimeKit
import SwiftUI

/// Form that creates a recipe or edits an existing one.
struct RecipeEditorView: View {
    let onSave: (Recipe) -> Void

    @State private var model: RecipeEditorModel
    @State private var editMode = EditMode.inactive
    @Environment(\.dismiss) private var dismiss

    /// Edits `recipe`, or creates a new one when it is `nil`.
    init(session: AppSession, recipe: Recipe?, onSave: @escaping (Recipe) -> Void) {
        self.onSave = onSave
        _model = State(initialValue: RecipeEditorModel(session: session, recipe: recipe))
    }

    var body: some View {
        NavigationStack {
            Form {
                RecipeBasicsSection(draft: $model.draft, courses: model.courses)
                RecipeCoverSection(model: model)
                RecipeTagsSection(model: model)
                RecipeIngredientsSection(draft: $model.draft, units: model.units, session: model.session)
                RecipeToolsSection(draft: $model.draft, session: model.session)
                RecipeStepsSection(draft: $model.draft)
            }
            .environment(\.editMode, $editMode)
            .navigationTitle(model.recipeID == nil ? "New recipe" : "Edit recipe")
            .navigationBarTitleDisplayMode(.inline)
            .sheetToolbar(confirm: "Save", isEnabled: model.draft.isComplete && !model.isSaving, onCancel: { dismiss() }, onConfirm: save)
            .task {
                await model.loadReferences()
            }
            .errorAlert($model.errorMessage)
        }
        .interactiveDismissDisabled()
    }

    private func save() {
        Task {
            if let recipe = await model.save() {
                onSave(recipe)
                dismiss()
            }
        }
    }
}
