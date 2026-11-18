import SwiftUI

/// Heading of a part of the editor with an optional hint and a button that switches the form between editing and reordering its rows.
struct ReorderHeader: View {
    let title: LocalizedStringKey
    var hint: LocalizedStringKey?

    @Environment(\.editMode) private var editMode

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Button(isReordering ? "Done" : "Reorder") {
                    withAnimation {
                        editMode?.wrappedValue = isReordering ? .inactive : .active
                    }
                }
                .font(.footnote)
            }
            if let hint {
                Text(hint)
                    .font(.footnote)
            }
        }
        .textCase(nil)
    }

    private var isReordering: Bool {
        editMode?.wrappedValue.isEditing == true
    }
}
