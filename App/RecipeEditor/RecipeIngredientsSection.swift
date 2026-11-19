import DinnertimeKit
import SwiftUI

/// The ingredient lines of a recipe in freely named groups; lines can be added, opened, reordered and deleted within their group.
struct RecipeIngredientsSection: View {
    @Binding var draft: RecipeDraft
    let units: [MeasureUnit]
    let session: AppSession

    var body: some View {
        ForEach($draft.ingredientGroups) { $group in
            Section {
                GroupFrame(group: $group, addTitle: "Add ingredient", onRemove: removal(of: group)) {
                    group.rows.append(IngredientDraft())
                } rows: {
                    ForEach($group.rows) { $line in
                        NavigationLink {
                            IngredientEditorView(line: $line, units: units, session: session)
                        } label: {
                            IngredientDraftRow(line: line, units: units)
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
                if group.id == draft.ingredientGroups.first?.id {
                    ReorderHeader(title: "Ingredients")
                }
            }
        }
        Section {
            Button("Add group", systemImage: "folder.badge.plus") {
                draft.ingredientGroups.append(RecipeGroup(rows: [IngredientDraft()]))
            }
        }
    }

    private func removal(of group: RecipeGroup<IngredientDraft>) -> (() -> Void)? {
        guard draft.ingredientGroups.count > 1 else {
            return nil
        }
        return {
            draft.ingredientGroups.removeAll { $0.id == group.id }
        }
    }
}
