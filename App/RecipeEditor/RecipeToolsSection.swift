import DinnertimeKit
import SwiftUI

/// The tools of a recipe as removable entries, added from the catalog of the household.
struct RecipeToolsSection: View {
    @Binding var draft: RecipeDraft
    let session: AppSession

    var body: some View {
        Section("Tools") {
            ForEach(draft.tools) { tool in
                Text(verbatim: tool.name)
            }
            .onDelete { offsets in
                draft.tools.remove(atOffsets: offsets)
            }
            NavigationLink {
                ToolPickerView(session: session, allowsCreation: true) { tool in
                    draft.addTool(tool)
                }
            } label: {
                Label("Add tool", systemImage: "plus")
            }
        }
    }
}
