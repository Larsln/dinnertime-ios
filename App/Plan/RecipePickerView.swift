import DinnertimeKit
import SwiftUI

/// Lets the user search the recipes and choose one.
struct RecipePickerView: View {
    let onSelect: (RecipeSummary) -> Void

    @State private var model: RecipeListModel
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, onSelect: @escaping (RecipeSummary) -> Void) {
        self.onSelect = onSelect
        _model = State(initialValue: RecipeListModel(session: session))
    }

    var body: some View {
        RecipeSearchList(model: model) { recipe in
            Button {
                onSelect(recipe)
                dismiss()
            } label: {
                RecipeRow(recipe: recipe)
            }
            .tint(.primary)
        }
        .navigationTitle("Choose recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}
