import SwiftUI

/// The favorite toggle and the menu that edits or deletes the recipe, in the navigation bar.
struct RecipeDetailToolbar: ToolbarContent {
    let model: RecipeDetailModel
    @Binding var showsEditor: Bool
    @Binding var confirmsDeletion: Bool

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            RecipeActionButtons(model: model, showsEditor: $showsEditor, confirmsDeletion: $confirmsDeletion)
        }
    }
}
