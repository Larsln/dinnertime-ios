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
            LabeledContent("Yield") {
                TextField("Yield", text: $draft.yieldText)
                    .multilineTextAlignment(.trailing)
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
