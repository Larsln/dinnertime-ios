import DinnertimeKit
import SwiftUI

/// Decides tonight's dinner: the members of the household say yes or no to the same recipes one at a time,
/// and the first one enough of them like is the match that can go on today's plan.
struct DinnerRoundView: View {
    let model: DinnerRoundModel
    /// Called with the entry of the plan once the match was planned for today.
    let onPlanned: (MealPlanEntry) -> Void

    @State private var confirmsEnd = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            DinnerRoundContent(model: model, isHeld: confirmsEnd, onPlan: plan, onClose: close)
                .paperScreen()
                .navigationTitle("What do we eat tonight?")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                    if model.phase.isVoting || model.phase == .waiting {
                        ToolbarItem(placement: .destructiveAction) {
                            Button("End round", role: .destructive) {
                                confirmsEnd = true
                            }
                        }
                    }
                }
                .confirmationDialog("End round", isPresented: $confirmsEnd, titleVisibility: .visible) {
                    Button("End round", role: .destructive) {
                        close(startsAgain: false)
                    }
                } message: {
                    Text("The round ends for everyone without anything being planned.")
                }
                .errorAlert($model.errorMessage)
        }
        .task {
            await model.load()
        }
    }

    /// Plans the match and shows its recipe.
    private func plan() {
        Task {
            if let entry = await model.plan() {
                dismiss()
                onPlanned(entry)
            }
        }
    }

    /// Closes the round and leaves, unless a new round is to be started right away.
    private func close(startsAgain: Bool) {
        Task {
            if await model.close(), !startsAgain {
                dismiss()
            }
        }
    }
}
