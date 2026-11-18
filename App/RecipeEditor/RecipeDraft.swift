import Foundation
import MealplannerKit

/// The content of a recipe while it is created or edited.
struct RecipeDraft {
    var title = ""
    var description = ""
    /// Key of the course.
    var course: String?
    var servings: Int?
    var yieldText = ""
    var prepMinutes: Int?
    var cookMinutes: Int?
    var sourceURL = ""
    /// The tools the recipe needs, from the catalog of the household.
    var tools: [Tool] = []
    /// Meal tags and tags of the recipe.
    var tagIDs: Set<Int> = []
    /// The ingredient lines by component; there is always at least one group.
    var ingredientGroups = [RecipeGroup(rows: [IngredientDraft()])]
    /// The steps by component; there is always at least one group.
    var stepGroups = [RecipeGroup(rows: [StepDraft()])]

    init() {}

    init(_ recipe: Recipe) {
        title = recipe.summary.title
        description = recipe.summary.description ?? ""
        course = recipe.summary.course
        servings = recipe.summary.servings
        yieldText = recipe.summary.yieldText ?? ""
        prepMinutes = recipe.summary.prepMinutes
        cookMinutes = recipe.summary.cookMinutes
        sourceURL = recipe.sourceURL?.absoluteString ?? ""
        tools = recipe.tools
        tagIDs = Set(recipe.summary.tags.map(\.id))
        if !recipe.ingredients.isEmpty {
            ingredientGroups = RecipeGroup.grouping(recipe.ingredients, by: \.section, row: IngredientDraft.init)
        }
        if !recipe.steps.isEmpty {
            stepGroups = RecipeGroup.grouping(recipe.steps, by: \.section, row: StepDraft.init)
        }
    }

    /// Whether the draft can be saved.
    var isComplete: Bool {
        title.nilIfBlank != nil
    }

    /// Adds a tool unless the recipe already lists it.
    mutating func addTool(_ tool: Tool) {
        if !tools.contains(where: { $0.id == tool.id }) {
            tools.append(tool)
        }
    }

    /// The draft as the API accepts it, without empty lines and steps; every row carries the title of its group as section.
    var input: RecipeInput {
        RecipeInput(
            title: title.nilIfBlank ?? "",
            description: description.nilIfBlank,
            course: course,
            servings: servings,
            yieldText: yieldText.nilIfBlank,
            prepMinutes: prepMinutes,
            cookMinutes: cookMinutes,
            sourceURL: sourceURL.nilIfBlank,
            tagIDs: tagIDs.sorted(),
            toolIDs: tools.map(\.id),
            ingredients: ingredientGroups.flattened { $0.input(section: $1) },
            steps: stepGroups.flattened { $0.input(section: $1) }
        )
    }
}
