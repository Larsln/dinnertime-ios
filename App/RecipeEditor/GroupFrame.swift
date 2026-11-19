import DinnertimeKit
import SwiftUI

/// The frame around one group of the recipe editor: its title, the rows inside and the buttons that add a row or remove the group.
struct GroupFrame<Row, Rows: View>: View {
    @Binding var group: RecipeGroup<Row>
    let addTitle: LocalizedStringKey
    /// Removes the group with its rows; `nil` for the only group, which stays.
    let onRemove: (() -> Void)?
    let onAdd: () -> Void
    @ViewBuilder let rows: () -> Rows

    var body: some View {
        TextField("Group name, e.g. base (optional)", text: $group.title)
            .font(.headline)
        rows()
        Button(addTitle, systemImage: "plus", action: onAdd)
        if let onRemove {
            Button("Remove group", systemImage: "trash", role: .destructive, action: onRemove)
        }
    }
}
