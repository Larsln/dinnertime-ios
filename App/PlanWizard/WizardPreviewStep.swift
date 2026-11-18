import MealplannerKit
import SwiftUI

/// Third step: the proposals, which can be locked and re-rolled before they are saved.
struct WizardPreviewStep: View {
    @Bindable var model: PlanWizardModel

    var body: some View {
        List {
            Section {
                ForEach(model.board.proposals, id: \.slot) { proposal in
                    ProposalRow(proposal: proposal, isLocked: model.board.isLocked(proposal.slot)) {
                        model.toggleLock(proposal.slot)
                    } onReroll: {
                        Task {
                            await model.reroll(proposal.slot)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("\(model.board.candidateCount) matching recipes for \(model.board.proposals.count) meals")
                    Spacer()
                    Button("Reroll all", systemImage: "dice") {
                        Task {
                            await model.suggest()
                        }
                    }
                    .font(.footnote)
                }
                .textCase(nil)
            }
            Section {
                Toggle("Then create the shopping list", isOn: $model.createsShoppingList)
            }
        }
        .overlay {
            if model.board.proposals.isEmpty {
                ContentUnavailableView("No matching recipes", systemImage: "fork.knife", description: Text("Change the preferences or choose other days."))
            }
        }
        .disabled(model.isWorking)
    }
}
