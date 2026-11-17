import MealplannerKit
import SwiftUI

/// Chooses the meals and servings the server fills the free slots of a week with.
struct GeneratePlanView: View {
    let week: Week
    let onGenerate: ([MealType], Int) async -> Bool

    @State private var meals: Set<MealType> = [.dinner]
    @State private var servings = 2
    @State private var isGenerating = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(MealType.allCases, id: \.self) { meal in
                        Toggle(isOn: binding(for: meal)) {
                            Text(verbatim: meal.label)
                        }
                    }
                } header: {
                    Text("Meals")
                } footer: {
                    Text("Every chosen meal without an entry gets a recipe. Recipes are picked so that opened packages are used up.")
                }
                Section {
                    Stepper("Servings: \(servings)", value: $servings, in: PlanEntryDraft.servingsRange)
                }
                if isGenerating {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(Text(verbatim: week.rangeText))
            .navigationBarTitleDisplayMode(.inline)
            .sheetToolbar(confirm: "Generate", isEnabled: !meals.isEmpty && !isGenerating, onCancel: { dismiss() }, onConfirm: generate)
        }
    }

    private func binding(for meal: MealType) -> Binding<Bool> {
        Binding(
            get: { meals.contains(meal) },
            set: { isOn in
                if isOn {
                    meals.insert(meal)
                } else {
                    meals.remove(meal)
                }
            }
        )
    }

    private func generate() {
        isGenerating = true
        Task {
            if await onGenerate(MealType.allCases.filter(meals.contains), servings) {
                dismiss()
            }
            isGenerating = false
        }
    }
}
