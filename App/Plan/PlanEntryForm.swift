import DinnertimeKit
import SwiftUI

/// Form that plans a recipe for a day and meal, or changes a planned one: another recipe, day or meal,
/// more or fewer servings.
struct PlanEntryForm: View {
    let session: AppSession
    let onSave: (PlanEntryDraft) async -> Bool

    @State private var draft: PlanEntryDraft
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, draft: PlanEntryDraft, onSave: @escaping (PlanEntryDraft) async -> Bool) {
        self.session = session
        self.onSave = onSave
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            PaperForm {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                Picker("Meal", selection: $draft.meal) {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Text(verbatim: meal.label)
                    }
                }
                NavigationLink {
                    RecipePickerView(session: session, onSelect: select)
                } label: {
                    LabeledContent("Recipe", value: draft.recipe?.title ?? String(localized: "Choose"))
                }
                Stepper("Servings: \(draft.servings)", value: $draft.servings, in: PlanEntryDraft.servingsRange)
            }
            .navigationTitle(draft.isChange ? "Change dish" : "Plan a meal")
            .navigationBarTitleDisplayMode(.inline)
            .sheetToolbar(confirm: draft.isChange ? "Save" : "Add", isEnabled: draft.recipe != nil && !isSaving, onCancel: { dismiss() }, onConfirm: save)
        }
    }

    private func select(_ recipe: RecipeSummary) {
        draft.recipe = recipe
    }

    private func save() {
        isSaving = true
        Task {
            if await onSave(draft) {
                dismiss()
            }
            isSaving = false
        }
    }
}
