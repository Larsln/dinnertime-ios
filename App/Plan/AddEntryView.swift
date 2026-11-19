import DinnertimeKit
import SwiftUI

/// Form that plans a recipe for a day and meal.
struct AddEntryView: View {
    let session: AppSession
    let onAdd: (PlanEntryDraft) async -> Bool

    @State private var draft: PlanEntryDraft
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, draft: PlanEntryDraft, onAdd: @escaping (PlanEntryDraft) async -> Bool) {
        self.session = session
        self.onAdd = onAdd
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
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
            .navigationTitle("Plan a meal")
            .navigationBarTitleDisplayMode(.inline)
            .sheetToolbar(confirm: "Add", isEnabled: draft.recipe != nil && !isSaving, onCancel: { dismiss() }, onConfirm: save)
        }
    }

    private func select(_ recipe: RecipeSummary) {
        draft.recipe = recipe
    }

    private func save() {
        isSaving = true
        Task {
            if await onAdd(draft) {
                dismiss()
            }
            isSaving = false
        }
    }
}
