import MealplannerKit
import SwiftUI

/// Title, description, course, servings, times and source of a recipe.
struct RecipeBasicsSection: View {
    @Binding var draft: RecipeDraft
    let courses: [Course]

    var body: some View {
        Section {
            TextField("Title", text: $draft.title)
            TextField("Description", text: $draft.description, axis: .vertical)
            Picker("Course", selection: $draft.course) {
                Text("No course")
                    .tag(String?.none)
                ForEach(courses) { course in
                    Text(verbatim: course.name)
                        .tag(String?.some(course.key))
                }
            }
        }
        Section {
            NumberField(title: "Servings", value: $draft.servings)
            VStack(alignment: .leading, spacing: 4) {
                Text("Number of pieces or amount")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. 12 cinnamon rolls or 1 tray", text: $draft.yieldText)
            }
            NumberField(title: "Preparation (min)", value: $draft.prepMinutes)
            NumberField(title: "Cooking (min)", value: $draft.cookMinutes)
            TextField("Source", text: $draft.sourceURL)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
}
