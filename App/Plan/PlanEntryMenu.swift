import DinnertimeKit
import SwiftUI

/// What can be done with a planned meal: change it, serve a side with it, move it or everything from its day on,
/// mark it as cooked or remove it. Shown as the context menu of a meal.
struct PlanEntryMenu: View {
    let entry: MealPlanEntry
    let model: PlanModel
    let onEdit: () -> Void
    /// Opens the side picker for the meal.
    let onAddSide: () -> Void

    var body: some View {
        Button("Change dish", systemImage: "pencil", action: onEdit)
        if entry.parentID == nil, entry.recipe.takesSides {
            Button("Add side", systemImage: "plus.circle", action: onAddSide)
        }
        Section {
            Button("One day later", systemImage: "arrow.right") {
                run { await model.move(entry, by: 1) }
            }
            Button("One day earlier", systemImage: "arrow.left") {
                run { await model.move(entry, by: -1) }
            }
        }
        PlanShiftButtons(day: entry.date, model: model)
        PortionVerdictMenu(entry: entry, model: model)
        Section {
            Button(entry.isCooked ? "Not cooked" : "Cooked", systemImage: entry.isCooked ? "arrow.uturn.backward" : "checkmark") {
                run { await model.toggleCooked(entry) }
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                run { await model.delete(entry) }
            }
        }
    }

    private func run(_ change: @escaping () async -> Void) {
        Task {
            await change()
        }
    }
}

/// Moves the whole plan from a day on, for when the household eats something else at short notice.
struct PlanShiftButtons: View {
    let day: DayDate
    let model: PlanModel

    var body: some View {
        Section {
            Button("Everything from here one day later", systemImage: "forward") {
                Task {
                    await model.shift(from: day, by: 1)
                }
            }
            Button("Everything from here one day earlier", systemImage: "backward") {
                Task {
                    await model.shift(from: day, by: -1)
                }
            }
        }
    }
}
