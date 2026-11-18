import MealplannerKit
import SwiftUI

/// Second step: what the planner weighs and which courses and tags it is restricted to.
struct WizardPreferencesStep: View {
    @Bindable var model: PlanWizardModel

    var body: some View {
        Form {
            Section {
                PreferenceToggle(title: "Use up leftovers", explanation: "opened packages and pantry first", isOn: $model.preferences.useLeftovers)
                PreferenceToggle(title: "Quick on weekdays", explanation: "Mon–Fri at most 30 min", isOn: $model.preferences.quickOnWeekdays)
                PreferenceToggle(title: "Long-uncooked first", explanation: "based on the plan so far", isOn: $model.preferences.preferNotRecent)
                PreferenceToggle(title: "Favorites more often", explanation: "favorites and well rated recipes", isOn: $model.preferences.preferFavorites)
                PreferenceToggle(title: "Variety", explanation: "no dish twice, not the same cuisine twice in a row", isOn: $model.preferences.variety)
            }
            Section("Only from") {
                ChipSelection(
                    addTitle: "Add course",
                    options: model.courses.map { ChipSelection.Option(id: $0.key, name: $0.name) },
                    selection: $model.courseKeys
                )
                ChipSelection(
                    addTitle: "Add tag",
                    options: model.tags.map { ChipSelection.Option(id: $0.id, name: $0.name) },
                    selection: $model.tagIDs
                )
            }
        }
        .task {
            await model.loadOptions()
        }
    }
}
