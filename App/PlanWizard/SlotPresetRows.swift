import DinnertimeKit
import SwiftUI

/// Two rows of quick choices that set the selection to a set of days and a set of meals.
struct SlotPresetRows: View {
    @Binding var selection: MealSlotSelection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ForEach(MealSlotSelection.DayPreset.allCases, id: \.self) { preset in
                    button(preset.label, isActive: selection.matchesPresets && selection.dayPreset == preset) {
                        selection.apply(preset)
                    }
                }
            }
            HStack {
                ForEach(MealSlotSelection.MealPreset.allCases, id: \.self) { preset in
                    button(preset.label, isActive: selection.matchesPresets && selection.mealPreset == preset) {
                        selection.apply(preset)
                    }
                }
            }
        }
    }

    private func button(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .buttonStyle(.bordered)
        .tint(isActive ? .accentColor : .secondary)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

extension MealSlotSelection.DayPreset {
    /// Title of the preset button.
    var label: String {
        switch self {
        case .allDays: String(localized: "All days")
        case .weekdays: String(localized: "Weekdays")
        case .weekend: String(localized: "Weekend")
        }
    }
}

extension MealSlotSelection.MealPreset {
    /// Title of the preset button.
    var label: String {
        switch self {
        case .dinner: String(localized: "preset.dinner", defaultValue: "Dinner")
        case .lunch: String(localized: "preset.lunch", defaultValue: "Lunch")
        case .allMeals: String(localized: "All meals")
        }
    }
}
