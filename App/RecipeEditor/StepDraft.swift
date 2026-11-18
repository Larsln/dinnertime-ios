import Foundation
import MealplannerKit

/// One step of the instructions while it is edited; its component is the group it belongs to.
struct StepDraft: Identifiable {
    let id = UUID()
    var text = ""

    init() {}

    init(_ step: RecipeStep) {
        text = step.text
    }

    /// The step as the API accepts it within `section`; `nil` for steps without text.
    func input(section: String?) -> RecipeInput.Step? {
        text.nilIfBlank.map { RecipeInput.Step(section: section, text: $0) }
    }
}
