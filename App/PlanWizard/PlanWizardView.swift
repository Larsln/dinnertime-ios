import MealplannerKit
import SwiftUI

/// Sheet that plans a week in three steps and saves the accepted proposals at the end.
struct PlanWizardView: View {
    /// Called after the proposals were saved, with the wish to create the shopping list.
    let onFinish: (Bool) -> Void

    @State private var model: PlanWizardModel
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, weeks: WeekSelection, plan: PlanModel, onFinish: @escaping (Bool) -> Void) {
        self.onFinish = onFinish
        _model = State(initialValue: PlanWizardModel(session: session, weeks: weeks, plan: plan))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch model.step {
                case .days:
                    WizardDaysStep(model: model)
                case .preferences:
                    WizardPreferencesStep(model: model)
                case .preview:
                    WizardPreviewStep(model: model)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                WizardStepIndicator(step: $model.step)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer
            }
            .navigationTitle("Plan week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .errorAlert($model.errorMessage)
        }
    }

    private var footer: some View {
        HStack {
            if model.step == .days {
                Text("\(model.selection.selected.count) meals")
                    .foregroundStyle(.secondary)
            }
            if model.isWorking {
                ProgressView()
            }
            Spacer()
            Button(action: advance) {
                switch model.step {
                case .days: Text("Next")
                case .preferences: Text("Suggest")
                case .preview: Text("Add \(model.board.proposals.count) meals")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAdvance)
        }
        .padding()
        .background(.bar)
    }

    private var canAdvance: Bool {
        guard !model.isWorking else {
            return false
        }
        return model.step == .preview ? !model.board.proposals.isEmpty : !model.selection.selected.isEmpty
    }

    private func advance() {
        switch model.step {
        case .days:
            model.step = .preferences
        case .preferences:
            Task {
                await model.suggest()
            }
        case .preview:
            Task {
                if await model.save() {
                    onFinish(model.createsShoppingList)
                    dismiss()
                }
            }
        }
    }
}
