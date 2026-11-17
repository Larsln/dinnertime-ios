import MealplannerKit
import SwiftUI

/// Menu that restricts the recipe list to one tag.
struct TagFilterMenu: View {
    @Bindable var model: RecipeListModel

    var body: some View {
        Menu("Filter", systemImage: isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
            Picker("Filter", selection: $model.query.tagID) {
                Text("All recipes")
                    .tag(Int?.none)
                section("Meals", kind: .meal)
                section("Categories", kind: .category)
                section("Tags", kind: .tag)
            }
        }
    }

    private var isActive: Bool {
        model.query.tagID != nil
    }

    private func section(_ title: LocalizedStringKey, kind: Tag.Kind) -> some View {
        Section(title) {
            ForEach(model.tags(of: kind)) { tag in
                Text(verbatim: tag.name)
                    .tag(Int?.some(tag.id))
            }
        }
    }
}
