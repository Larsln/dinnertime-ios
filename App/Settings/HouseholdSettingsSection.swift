import DinnertimeKit
import SwiftUI

/// The settings of the household: the usual number of servings and what the shopping list notes.
struct HouseholdSettingsSection: View {
    @Environment(HouseholdStore.self) private var household

    var body: some View {
        @Bindable var household = household
        Section {
            Stepper(value: servings, in: HouseholdSettings.servingsRange) {
                LabeledContent("Usual number of servings", value: household.defaultServings, format: .number)
            }
        } header: {
            Text("Household")
        } footer: {
            Text("Recipes are shown, planned and shopped for this many servings unless you choose otherwise.")
        }
        Section {
            Toggle("Show what is in stock on the shopping list", isOn: showsStock)
        } footer: {
            Text("What the planned meals need and is at home already is noted below the list, so that you can check it.")
        }
        .task {
            await household.load()
        }
        .errorAlert($household.errorMessage)
    }

    private var servings: Binding<Int> {
        Binding(
            get: { household.defaultServings },
            set: { servings in
                Task {
                    await household.setDefaultServings(servings)
                }
            }
        )
    }

    private var showsStock: Binding<Bool> {
        Binding(
            get: { household.showStockedNeeds },
            set: { shown in
                Task {
                    await household.setShowStockedNeeds(shown)
                }
            }
        )
    }
}
