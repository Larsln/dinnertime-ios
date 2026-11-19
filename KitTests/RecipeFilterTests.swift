import Foundation
import Testing
@testable import DinnertimeKit

/// The filters of the recipe list as the local copy answers them: courses and meals widen, other tags narrow.
struct RecipeFilterTests {
    private static let breakfast = 1325
    private static let lunch = 1326
    private static let snack = 1329
    private static let vegetarian = 1330
    private static let quick = 1332
    private static let mexican = 1338
    private static let party = 1344

    private func titles(_ endpoint: Endpoint<Page<RecipeSummary>>) async throws -> [String] {
        let store = try await OfflineSupport.syncedStore()
        return try #require(await store.answer(endpoint)).response.items.map(\.title)
    }

    @Test func aRecipeHasToSuitOneOfTheMeals() async throws {
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.lunch])) == ["Crispy Chicken Tacos", "Hummus", "Nudeln mit Hackfleisch und Käse"])
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.snack])) == ["Guacamole", "Hummus"])
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.lunch, Self.snack])).count == 4)
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.breakfast, Self.snack])) == ["Guacamole", "Hummus"])
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.breakfast])).isEmpty)
    }

    @Test func aRecipeHasToCarryAllOtherTags() async throws {
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.mexican])) == ["Crispy Chicken Tacos", "Guacamole"])
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.vegetarian])) == ["Guacamole", "Hummus"])
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.mexican, Self.vegetarian])) == ["Guacamole"])
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.mexican, Self.vegetarian, Self.quick, Self.party])) == ["Guacamole"])
    }

    @Test func aRecipeHasToBeOfOneOfTheCourses() async throws {
        #expect(try await titles(RecipeEndpoints.list(courses: ["starter"])) == ["Guacamole", "Hummus"])
        #expect(try await titles(RecipeEndpoints.list(courses: ["starter", "main"])).count == 4)
        #expect(try await titles(RecipeEndpoints.list(courses: ["soup", "main"])) == ["Crispy Chicken Tacos", "Nudeln mit Hackfleisch und Käse"])
        #expect(try await titles(RecipeEndpoints.list(courses: ["soup"])).isEmpty)
    }

    @Test func theGroupsNarrowEachOther() async throws {
        let mealsAndTag = RecipeEndpoints.list(tagIDs: [Self.lunch, Self.snack, Self.mexican])
        let everything = RecipeEndpoints.list(search: "a", tagIDs: [Self.lunch, Self.snack, Self.mexican], courses: ["starter", "soup"])

        #expect(try await titles(mealsAndTag) == ["Crispy Chicken Tacos", "Guacamole"])
        #expect(try await titles(everything) == ["Guacamole"])
        #expect(try await titles(RecipeEndpoints.list(tagIDs: [Self.lunch, Self.vegetarian], courses: ["main"])).isEmpty)
    }

    @Test func favoritesNarrowWhatTheOtherFiltersLeave() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(RecipeMarkEndpoints.setFavorite(true, id: 98))
        let found = try #require(await store.answer(RecipeEndpoints.list(tagIDs: [Self.snack], courses: ["starter", "main"], favoritesOnly: true)))

        #expect(found.response.items.map(\.title) == ["Hummus"])
    }

    @Test func listsReachTheLocalCopyWithEveryValue() throws {
        let request = try LocalRequest(RecipeEndpoints.list(search: "x", tagIDs: [1, 2], courses: ["main", "soup"]))

        #expect(request.lists == ["tags": ["1", "2"], "courses": ["main", "soup"]])
        #expect(request.query == ["page": "1", "search": "x"])
    }
}
