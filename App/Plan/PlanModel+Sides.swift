import DinnertimeKit

/// The sides of the planned meals.
extension PlanModel {
    /// The sides served with a meal.
    func sides(of entry: MealPlanEntry) -> [MealPlanEntry] {
        entries.sides(of: entry)
    }

    /// Serves a recipe as a side with a planned meal.
    func addSide(_ recipe: RecipeSummary, to entry: MealPlanEntry) async {
        await change {
            _ = try await session.send(MealPlanEndpoints.addSide(recipeID: recipe.id, to: entry.id))
        }
    }

    /// Brings the sides of a saved meal in line with a draft: those taken out are removed and the new ones are added.
    ///
    /// Sides are removed before the meal is saved, because a meal that gets another dish drops the sides that do not
    /// fit it on its own.
    func saveSides(of draft: PlanEntryDraft, around save: () async throws -> MealPlanEntry) async throws {
        for side in draft.removedSides {
            try await session.send(MealPlanEndpoints.delete(id: side.id))
        }
        let entry = try await save()
        for recipe in draft.addedSides {
            _ = try await session.send(MealPlanEndpoints.addSide(recipeID: recipe.id, to: entry.id))
        }
    }
}
