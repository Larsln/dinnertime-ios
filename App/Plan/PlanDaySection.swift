import MealplannerKit
import SwiftUI

/// One day of the plan: its date, a badge on today and its entries as cards, or a compact row when nothing is planned.
struct PlanDaySection: View {
    let day: DayDate
    let model: PlanModel
    let onAdd: () -> Void

    var body: some View {
        let entries = model.entries(on: day)
        Section {
            if entries.isEmpty {
                HStack {
                    Text("Nothing planned")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    addButton
                        .buttonStyle(.borderless)
                }
            }
            ForEach(entries) { entry in
                NavigationLink(value: entry.recipe) {
                    PlanEntryRow(entry: entry)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task {
                            await model.delete(entry)
                        }
                    }
                }
                .swipeActions(edge: .leading) {
                    Button(entry.isCooked ? "Not cooked" : "Cooked", systemImage: entry.isCooked ? "arrow.uturn.backward" : "checkmark") {
                        Task {
                            await model.toggleCooked(entry)
                        }
                    }
                    .tint(.green)
                }
            }
        } header: {
            HStack(spacing: 8) {
                Text(verbatim: day.longText)
                if day == DayDate(.now) {
                    Text("Today")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tint, in: .capsule)
                }
                Spacer()
                if !entries.isEmpty {
                    addButton
                }
            }
            .textCase(nil)
            .id(day)
        }
    }

    private var addButton: some View {
        Button("Plan a meal", systemImage: "plus", action: onAdd)
            .labelStyle(.iconOnly)
    }
}
