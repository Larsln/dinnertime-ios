import DinnertimeKit
import SwiftUI

extension PortionVerdict {
    /// The verdict in words.
    var label: String {
        switch self {
        case .tooSmall: String(localized: "Too small")
        case .right: String(localized: "Just right")
        case .tooBig: String(localized: "Too big")
        }
    }
}

/// The portions a planned meal cooks, whole ones counted and others as a decimal number.
struct PortionsText: View {
    let entry: MealPlanEntry

    var body: some View {
        if let whole = entry.wholePortions {
            Text("\(whole) servings")
        } else {
            Text("\(entry.portionsText()) servings")
        }
    }
}

/// The menu in which the signed-in user says how the portion of a meal was, offered from the day of the meal on.
struct PortionVerdictMenu: View {
    let entry: MealPlanEntry
    let model: PlanModel

    var body: some View {
        if !(DayDate(.now) < entry.date) {
            Menu("Portion", systemImage: "chart.bar") {
                ForEach(PortionVerdict.allCases, id: \.self) { verdict in
                    Button {
                        Task {
                            await model.judgePortion(of: entry, as: verdict)
                        }
                    } label: {
                        if model.ownVerdict(on: entry) == verdict {
                            Label(verdict.label, systemImage: "checkmark")
                        } else {
                            Text(verbatim: verdict.label)
                        }
                    }
                }
            }
        }
    }
}

/// What the signed-in user said about the portion of a meal, as a small line on its card.
struct PortionVerdictNote: View {
    let verdict: PortionVerdict?

    var body: some View {
        if let verdict {
            Text("Portion: \(verdict.label)")
                .font(.caption)
                .foregroundStyle(.inkMuted)
        }
    }
}
