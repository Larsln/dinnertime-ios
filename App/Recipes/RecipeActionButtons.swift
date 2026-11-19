import SwiftUI

/// The favorite toggle and the menu that edits or deletes a recipe.
struct RecipeActionButtons: View {
    let model: RecipeDetailModel
    @Binding var showsEditor: Bool
    @Binding var confirmsDeletion: Bool

    var body: some View {
        Button(
            model.summary.isFavorite ? "Remove from favorites" : "Add to favorites",
            systemImage: model.summary.isFavorite ? "heart.fill" : "heart"
        ) {
            Task {
                await model.toggleFavorite()
            }
        }
        Menu("Actions", systemImage: "ellipsis.circle") {
            Button("Edit", systemImage: "pencil") {
                showsEditor = true
            }
            Button("Delete", systemImage: "trash", role: .destructive) {
                confirmsDeletion = true
            }
        }
        .disabled(model.recipe == nil)
    }
}
