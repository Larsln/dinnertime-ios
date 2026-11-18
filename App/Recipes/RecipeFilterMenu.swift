import MealplannerKit
import SwiftUI

/// Menu that restricts the recipe list to favorites, one course and one tag.
struct RecipeFilterMenu: View {
    @Bindable var model: RecipeListModel

    var body: some View {
        Menu("Filter", systemImage: model.query.isFiltered ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle") {
            Toggle("Favorites only", systemImage: "heart", isOn: $model.query.favoritesOnly)
            Picker("Course", selection: $model.query.course) {
                Text("All courses")
                    .tag(String?.none)
                ForEach(model.courses) { course in
                    Text(verbatim: course.name)
                        .tag(String?.some(course.key))
                }
            }
            .pickerStyle(.menu)
            Picker("Tag", selection: $model.query.tagID) {
                Text("All tags")
                    .tag(Int?.none)
                section("Meals", kind: .meal)
                section("Tags", kind: .tag)
            }
            .pickerStyle(.menu)
        }
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
