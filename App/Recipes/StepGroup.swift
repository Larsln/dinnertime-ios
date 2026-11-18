import MealplannerKit

/// Consecutive steps that share a section heading.
struct StepGroup: Identifiable {
    /// Position of the group within the recipe.
    let id: Int
    /// Heading of the component, such as "Filling".
    let title: String?
    let steps: [RecipeStep]
}

extension Recipe {
    /// The steps in recipe order, split wherever the section heading changes.
    var stepGroups: [StepGroup] {
        var groups: [StepGroup] = []
        for step in steps {
            if let last = groups.last, last.title == step.section {
                groups[groups.count - 1] = StepGroup(id: last.id, title: last.title, steps: last.steps + [step])
            } else {
                groups.append(StepGroup(id: groups.count, title: step.section, steps: [step]))
            }
        }
        return groups
    }
}
