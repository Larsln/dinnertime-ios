import DinnertimeKit
import SwiftUI

/// The steps of a recipe in freely named groups, numbered across all groups; steps are edited in place and can be added, reordered and deleted within their group.
struct RecipeStepsSection: View {
    @Binding var draft: RecipeDraft

    var body: some View {
        let numbers = stepNumbers
        ForEach($draft.stepGroups) { $group in
            Section {
                GroupFrame(group: $group, addTitle: "Add step", onRemove: removal(of: group)) {
                    group.rows.append(StepDraft())
                } rows: {
                    ForEach($group.rows) { $step in
                        HStack(alignment: .top, spacing: 8) {
                            Text(verbatim: "\(numbers[step.id] ?? 0).")
                                .monospacedDigit()
                                .foregroundStyle(.inkMuted)
                            TextField("Step", text: $step.text, axis: .vertical)
                                .keyboardDoneButton()
                        }
                    }
                    .onMove { offsets, destination in
                        group.rows.move(fromOffsets: offsets, toOffset: destination)
                    }
                    .onDelete { offsets in
                        group.rows.remove(atOffsets: offsets)
                    }
                }
            } header: {
                if group.id == draft.stepGroups.first?.id {
                    ReorderHeader(title: "Method", hint: "Steps can be combined into groups, such as base, filling and decoration.")
                }
            } footer: {
                if group.id == draft.stepGroups.last?.id {
                    Text("Amounts in curly braces, e.g. {200} g, adapt to the servings.")
                }
            }
        }
        Section {
            Button("Add group", systemImage: "folder.badge.plus") {
                draft.stepGroups.append(RecipeGroup(rows: [StepDraft()]))
            }
        }
    }

    /// Position of every step, counted across all groups.
    private var stepNumbers: [UUID: Int] {
        let steps = draft.stepGroups.flatMap(\.rows)
        return Dictionary(uniqueKeysWithValues: steps.enumerated().map { ($1.id, $0 + 1) })
    }

    private func removal(of group: RecipeGroup<StepDraft>) -> (() -> Void)? {
        guard draft.stepGroups.count > 1 else {
            return nil
        }
        return {
            draft.stepGroups.removeAll { $0.id == group.id }
        }
    }
}
