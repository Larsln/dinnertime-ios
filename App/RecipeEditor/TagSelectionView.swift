import MealplannerKit
import SwiftUI

/// A list of tags of which any number can be chosen.
struct TagSelectionView: View {
    let title: LocalizedStringKey
    let tags: [Tag]
    @Binding var selection: Set<Int>

    var body: some View {
        List(tags) { tag in
            Button {
                toggle(tag)
            } label: {
                HStack {
                    Text(verbatim: tag.name)
                    Spacer()
                    if selection.contains(tag.id) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .tint(.primary)
            .accessibilityAddTraits(selection.contains(tag.id) ? .isSelected : [])
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ tag: Tag) {
        if selection.contains(tag.id) {
            selection.remove(tag.id)
        } else {
            selection.insert(tag.id)
        }
    }
}
