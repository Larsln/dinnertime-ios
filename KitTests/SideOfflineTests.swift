import Foundation
import Testing
@testable import DinnertimeKit

/// Sides on the local copy: which ones a dish is offered and how they stay with their meal.
struct SideOfflineTests {
    private let day = SideSupport.day

    private func options(_ store: OfflineStore, for recipeID: Int) async throws -> [String] {
        try #require(await store.answer(RecipeEndpoints.sides(of: recipeID))).response.map(\.title)
    }

    @Test func onlySidesOfFittingKindsAreOfferedTheLatestFirst() async throws {
        let store = try await SideSupport.store(entries: [
            SideSupport.entry(10, recipe: SideSupport.schnitzel, date: day.adding(days: -7)),
            SideSupport.entry(11, recipe: SideSupport.rice, date: day.adding(days: -7), parent: 10),
            SideSupport.entry(20, recipe: SideSupport.schnitzel, date: day.adding(days: -3)),
            SideSupport.entry(21, recipe: SideSupport.bakedPotatoes, date: day.adding(days: -3), parent: 20),
            SideSupport.entry(30, recipe: SideSupport.curry, date: day),
            SideSupport.entry(31, recipe: SideSupport.fries, date: day, parent: 30),
        ])

        #expect(try await options(store, for: SideSupport.schnitzel) == ["Ofenkartoffeln", "Reis", "Fritten"])
        #expect(try await options(store, for: SideSupport.curry) == ["Reis"])
        #expect(try await options(store, for: SideSupport.rice).isEmpty)
        #expect(try await options(try await SideSupport.store(), for: SideSupport.schnitzel) == ["Fritten", "Ofenkartoffeln", "Reis"])
    }

    @Test func aSideSharesDayMealAndEatersWithItsMealAndIsQueued() async throws {
        let eaters: [String: Any] = ["servings": 3, "guests": 1, "portions": 3.02, "eaters": [["user_id": 1, "name": "Anna", "factor": 1.15], ["user_id": 2, "name": "Ben", "factor": 0.87]]]
        let store = try await SideSupport.store(entries: [SideSupport.entry(10, recipe: SideSupport.schnitzel, extra: eaters)])
        let side = try await SideSupport.serve(SideSupport.fries, in: store)
        let queued = try #require(await store.pendingChanges.last)

        #expect(side.id < 0)
        #expect(side.parentID == 10)
        #expect(side.date == day)
        #expect(side.meal == .dinner)
        #expect(side.servings == 3)
        #expect(side.guests == 1)
        #expect(side.eaters?.map(\.userID) == [1, 2])
        #expect(side.portions == 3)
        #expect(queued.method == .post)
        #expect(queued.path == "meal-plan/10/sides")
        #expect(queued.created == [side.id])
        let plan = try await SideSupport.plan(store)
        #expect(plan.meals.map(\.id) == [10])
        #expect(plan.sides(of: try #require(plan.meals.first)).map(\.recipe.title) == ["Fritten"])
    }

    @Test func aSideOfAKindTheDishIsNotServedWithIsRefused() async throws {
        let store = try await SideSupport.store()
        let side = try await SideSupport.serve(SideSupport.fries, in: store)

        await #expect(throws: APIError.self) {
            try await SideSupport.serve(SideSupport.noodles, in: store)
        }
        await #expect(throws: APIError.self) {
            try await SideSupport.serve(SideSupport.rice, with: side.id, in: store)
        }
        #expect(await store.pendingCount == 1)
    }

    @Test func sidesFollowTheirMeal() async throws {
        let store = try await SideSupport.store()
        let side = try await SideSupport.serve(SideSupport.fries, in: store)
        _ = try await store.answer(MealPlanEndpoints.update(id: 10, date: day.adding(days: 2), meal: .lunch, recipeID: SideSupport.schnitzel, eaterIDs: [1], guests: 3))
        _ = try await store.answer(MealPlanEndpoints.setCooked(true, id: 10))
        let followed = try #require(try await SideSupport.plan(store).first { $0.id == side.id })

        #expect(followed.parentID == 10)
        #expect(followed.date == day.adding(days: 2))
        #expect(followed.meal == .lunch)
        #expect(followed.servings == 4)
        #expect(followed.eaters?.map(\.userID) == [1])
        #expect(followed.isCooked)

        _ = try await store.answer(MealPlanEndpoints.shift(from: day, days: 1))
        #expect(try await SideSupport.plan(store).map(\.date) == [day.adding(days: 2), day.adding(days: 2)])
        _ = try await store.answer(MealPlanEndpoints.setCooked(false, id: 10))
        _ = try await store.answer(MealPlanEndpoints.shift(from: day, days: 1))
        #expect(try await SideSupport.plan(store).map(\.date) == [day.adding(days: 3), day.adding(days: 3)])

        _ = try await store.answer(MealPlanEndpoints.delete(id: 10))
        #expect(try await SideSupport.plan(store).isEmpty)
    }

    @Test func anotherDishKeepsOnlyTheSidesItIsServedWith() async throws {
        let store = try await SideSupport.store()
        try await SideSupport.serve(SideSupport.fries, in: store)
        try await SideSupport.serve(SideSupport.rice, in: store)
        _ = try await store.answer(MealPlanEndpoints.update(id: 10, date: day, meal: .dinner, recipeID: SideSupport.curry, servings: 2))
        let plan = try await SideSupport.plan(store)

        #expect(plan.meals.map(\.recipe.title) == ["Curry"])
        #expect(plan.count == 2)
        #expect(plan.sides(of: try #require(plan.meals.first)).map(\.recipe.title) == ["Reis"])
    }

    @Test func aSideThatIsMovedBecomesAMealOfItsOwn() async throws {
        let store = try await SideSupport.store()
        let side = try await SideSupport.serve(SideSupport.fries, in: store)
        let kept = try #require(await store.answer(MealPlanEndpoints.update(id: side.id, date: day, meal: .dinner, recipeID: SideSupport.fries, servings: 2))).response
        let moved = try #require(await store.answer(MealPlanEndpoints.update(id: side.id, date: day.adding(days: 1), meal: .dinner, recipeID: SideSupport.fries, servings: 2))).response

        #expect(kept.parentID == 10)
        #expect(moved.parentID == nil)
        #expect(try await SideSupport.plan(store).meals.map(\.id) == [10, side.id])
    }

    @Test func deletingARecipeTakesItsMealsAndTheirSidesAlong() async throws {
        let store = try await SideSupport.store()
        try await SideSupport.serve(SideSupport.fries, in: store)
        _ = try await store.answer(RecipeEndpoints.delete(id: SideSupport.schnitzel))

        #expect(try await SideSupport.plan(store).isEmpty)
    }

    @Test func aSideOfAMealPlannedOfflineIsSentWithTheRealIdOfTheMeal() async throws {
        let store = try await SideSupport.store()
        let meal = try #require(await store.answer(MealPlanEndpoints.create(date: day.adding(days: 1), meal: .dinner, recipeID: SideSupport.curry, servings: 2))).response
        let side = try await SideSupport.serve(SideSupport.rice, with: meal.id, in: store)
        let sent = SentPaths()
        _ = await store.drain { entry, _ in
            await sent.note(entry.path)
            return OfflineSupport.created(id: entry.path == "meal-plan" ? 40 : 41, extra: entry.path == "meal-plan" ? [:] : ["parent_id": 40])
        }
        let plan = try await SideSupport.plan(store)

        #expect(side.parentID == meal.id)
        #expect(await sent.paths == ["meal-plan", "meal-plan/40/sides"])
        #expect(plan.first { $0.id == 41 }?.parentID == 40)
        #expect(plan.meals.map(\.id) == [10, 40])
    }

    @Test func aRecipeBecomesASideOffline() async throws {
        let store = try await SideSupport.store()
        let changed = try #require(await store.answer(RecipeEndpoints.update(id: SideSupport.curry, RecipeInput(title: "Curry", sideKind: "rice")))).response

        #expect(changed.summary.sideKind == "rice")
        #expect(changed.summary.sideOptions.isEmpty)
        #expect(try await options(store, for: SideSupport.schnitzel) == ["Curry", "Fritten", "Ofenkartoffeln", "Reis"])
    }
}

/// Records the paths of the changes a drain sent.
private actor SentPaths {
    private(set) var paths: [String] = []

    func note(_ path: String) {
        paths.append(path)
    }
}
