import DinnertimeKit
import SwiftUI

/// The meal tags and tags of a recipe, each group chosen on its own screen.
struct RecipeTagsSection: View {
    @Bindable var model: RecipeEditorModel

    var body: some View {
        Section {
            link("Meals", kind: .meal)
            link("Tags", kind: .tag)
        }
    }

    private func link(_ title: LocalizedStringKey, kind: Tag.Kind) -> some View {
        let tags = model.tags(of: kind)
        return NavigationLink {
            TagSelectionView(title: title, tags: tags, selection: $model.draft.tagIDs)
        } label: {
            LabeledContent(title) {
                Text(verbatim: tags.filter { model.draft.tagIDs.contains($0.id) }.map(\.name).joined(separator: ", "))
            }
        }
    }
}
