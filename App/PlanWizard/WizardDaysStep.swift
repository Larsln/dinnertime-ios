import DinnertimeKit
import SwiftUI

/// First step: the week, the matrix of days and meals with its presets, and the servings.
struct WizardDaysStep: View {
    @Bindable var model: PlanWizardModel

    var body: some View {
        @Bindable var weeks = model.weeks
        PaperForm {
            Section {
                PlanWeekHeader(week: $weeks.week)
                    .buttonStyle(.borderless)
                    .listRowInsets(EdgeInsets())
                SlotPresetRows(selection: $model.selection)
            }
            Section {
                SlotMatrix(selection: $model.selection)
                Button(model.selection.showsAllMeals ? "Hide additional meals" : "Show more meals") {
                    model.selection.showsAllMeals.toggle()
                }
            } footer: {
                Text("Tap the cells that should be filled. What is planned already stays as it is.")
            }
            Section {
                Stepper("Servings: \(model.servings)", value: $model.servings, in: HouseholdSettings.servingsRange)
            }
        }
        .onChange(of: model.weeks.week) {
            model.resetSelection()
        }
        .onChange(of: model.plannedSlots) {
            model.resetSelection()
        }
    }
}
