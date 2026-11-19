import DinnertimeKit
import SwiftUI

/// A recipe with its rating at the top, its ingredients and method and the ways to change it.
///
/// On narrow screens the ingredients and the method stand on two segments, on wide screens side by side.
struct RecipeDetailView: View {
    let session: AppSession
    /// Whether the recipe stands next to the list instead of on a screen of its own, which has a navigation bar for its controls.
    let isEmbedded: Bool
    let onUpdate: (RecipeSummary) -> Void
    let onDelete: () -> Void

    @State private var model: RecipeDetailModel
    @State private var showsEditor = false
    @State private var confirmsDeletion = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(HouseholdStore.self) private var household

    init(
        session: AppSession,
        summary: RecipeSummary,
        plannedServings: Int? = nil,
        isEmbedded: Bool = false,
        onUpdate: @escaping (RecipeSummary) -> Void = { _ in },
        onDelete: @escaping () -> Void = {}
    ) {
        self.session = session
        self.isEmbedded = isEmbedded
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _model = State(initialValue: RecipeDetailModel(session: session, summary: summary, plannedServings: plannedServings))
    }

    var body: some View {
        Group {
            if isEmbedded {
                RecipeWideLayout(model: model) {
                    HStack(spacing: 4) {
                        RecipeActionButtons(model: model, showsEditor: $showsEditor, confirmsDeletion: $confirmsDeletion)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                }
            } else {
                screen
            }
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

    /// The recipe as a screen of its own, with its controls in the navigation bar.
    private var screen: some View {
        Group {
            if sizeClass == .regular {
                RecipeWideLayout(model: model) {}
            } else {
                RecipeCompactLayout(model: model)
            }
        }
        .navigationTitle(Text(verbatim: model.summary.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(removing: .title)
        .toolbar {
            RecipeDetailToolbar(model: model, showsEditor: $showsEditor, confirmsDeletion: $confirmsDeletion)
        }
    }

    private func delete() {
        Task {
            if await model.delete() {
                onDelete()
                if !isEmbedded {
                    dismiss()
                }
            }
        }
    }
}
