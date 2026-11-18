import MealplannerKit
import SwiftUI

/// The settings of the household: the usual number of servings.
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
}
