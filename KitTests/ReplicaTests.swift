import Foundation
import Testing
@testable import MealplannerKit

/// The local copy: applying the feed, persistence and reads.
struct ReplicaTests {
    @Test func appliesTheRecordedFeed() async throws {
        let store = try await OfflineSupport.syncedStore()
        let recipes = try #require(await store.answer(RecipeEndpoints.list())).response
        let tools = try #require(await store.answer(ToolEndpoints.search(""))).response

        #expect(await store.hasSynced)
        #expect(await store.syncVersion == 126)
        #expect(await store.defaultServings == 2)
        #expect(recipes.items.map(\.title) == ["Crispy Chicken Tacos", "Guacamole", "Hummus", "Nudeln mit Hackfleisch und Käse"])
        #expect(!recipes.hasMore)
        #expect(tools.count == 14)
    }

    @Test func survivesARestart() async throws {
        let directory = OfflineSupport.directory()
        _ = try await OfflineSupport.syncedStore(in: directory)
        let reopened = OfflineStore(directory: directory)
        let recipe = try #require(await reopened.answer(RecipeEndpoints.detail(id: 95))).response

        #expect(await reopened.syncVersion == 126)
        #expect(recipe.summary.title == "Crispy Chicken Tacos")
        #expect(recipe.ingredients.first?.product?.id == 67)
    }

    @Test func appliesChangesAndDeletions() async throws {
        let store = try await OfflineSupport.syncedStore()
        let page = try OfflineSupport.page(
            version: 130,
            changed: ["recipes": [OfflineSupport.recipe(id: 500, title: "Apfelkuchen")]],
            deleted: ["recipes": [98], "meal_plan_entries": [21]]
        )
        let progress = try await store.applySync(page)
        let titles = try #require(await store.answer(RecipeEndpoints.list())).response.items.map(\.title)

        #expect(progress == SyncProgress(hasMore: false, areas: [.recipes, .plan], peerKey: "key"))
        #expect(titles == ["Apfelkuchen", "Crispy Chicken Tacos", "Guacamole", "Nudeln mit Hackfleisch und Käse"])
        #expect(await store.syncVersion == 130)
        #expect(await store.defaultServings == 3)
        await #expect(throws: APIError.server(status: 404, message: nil)) {
            _ = try await store.answer(RecipeEndpoints.detail(id: 98))
        }
    }

    @Test func pagesAdvanceTheVersionOneByOne() async throws {
        let store = OfflineStore(directory: OfflineSupport.directory())
        let first = try await store.applySync(OfflineSupport.page(version: 5, hasMore: true, changed: ["recipes": [OfflineSupport.recipe(id: 1, title: "A")]]))

        #expect(first.hasMore)
        #expect(await store.syncVersion == 5)

        let second = try await store.applySync(OfflineSupport.page(version: 9, changed: ["recipes": [OfflineSupport.recipe(id: 2, title: "B")]]))

        #expect(!second.hasMore)
        #expect(await store.syncVersion == 9)
        #expect(try #require(await store.answer(RecipeEndpoints.list())).response.items.map(\.title) == ["A", "B"])
    }

    @Test func aBrokenPageLeavesTheVersionUntouched() async throws {
        let store = try await OfflineSupport.syncedStore()

        await #expect(throws: (any Error).self) {
            _ = try await store.applySync(Data("{}".utf8))
        }
        #expect(await store.syncVersion == 126)
    }

    @Test func filtersRecipesLocally() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(RecipeMarkEndpoints.setFavorite(true, id: 97))

        func titles(_ endpoint: Endpoint<Page<RecipeSummary>>) async throws -> [String] {
            try #require(await store.answer(endpoint)).response.items.map(\.title)
        }

        #expect(try await titles(RecipeEndpoints.list(search: "CHICKEN")) == ["Crispy Chicken Tacos"])
        #expect(try await titles(RecipeEndpoints.list(course: "starter")) == ["Guacamole", "Hummus"])
        #expect(try await titles(RecipeEndpoints.list(tagID: 1334)) == ["Crispy Chicken Tacos", "Nudeln mit Hackfleisch und Käse"])
        #expect(try await titles(RecipeEndpoints.list(favoritesOnly: true)) == ["Guacamole"])
        #expect(try await titles(RecipeEndpoints.list(search: "u", course: "starter", favoritesOnly: true)) == ["Guacamole"])
        #expect(try await titles(RecipeEndpoints.list(search: "xyz")).isEmpty)
    }

    @Test func servesThePlanThePantryAndTheCurrentList() async throws {
        let store = try await OfflineSupport.syncedStore()
        let from = DayDate(year: 2026, month: 11, day: 19)
        let entries = try #require(await store.answer(MealPlanEndpoints.entries(from: from, to: from.adding(days: 1)))).response
        let pantry = try #require(await store.answer(PantryEndpoints.list)).response
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(entries.map(\.id) == [22, 23])
        #expect(entries.first?.recipe.title == "Crispy Chicken Tacos")
        #expect(pantry.count == 19)
        #expect(pantry.map(\.expiresOn) == pantry.map(\.expiresOn).sorted { ($0?.description ?? "9") < ($1?.description ?? "9") })
        #expect(list.id == 11)
        #expect(list.items.count == 11)
    }

    @Test func withoutAListTheCurrentOneIsMissing() async throws {
        let store = OfflineStore(directory: OfflineSupport.directory())
        _ = try await store.applySync(OfflineSupport.page(version: 1))

        await #expect(throws: APIError.server(status: 404, message: nil)) {
            _ = try await store.answer(ShoppingEndpoints.current)
        }
    }

    @Test func embeddedRecordsShowTheCopysOwnVersion() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(ToolEndpoints.rename(id: 21, to: "Bratpfanne"))
        let input = ProductInput(name: "Avocado Hass", icon: "avocado", storeSectionID: 729, baseUnit: .piece, isPantryStaple: false, shelfLifeOpenedDays: 2)
        _ = try await store.answer(ProductEndpoints.update(id: 95, input))
        let recipe = try #require(await store.answer(RecipeEndpoints.detail(id: 95))).response
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let avocado = try #require(list.items.first { $0.product?.id == 95 }?.product)

        #expect(recipe.tools.first { $0.id == 21 }?.name == "Bratpfanne")
        #expect(avocado.name == "Avocado Hass")
        #expect(avocado.storeSection?.id == 729)
    }

    @Test func countsRecipesPerProductAndToolLocally() async throws {
        let store = try await OfflineSupport.syncedStore()
        let product = try #require(await store.answer(ProductEndpoints.detail(id: 68))).response
        let tools = try #require(await store.answer(ToolEndpoints.search(""))).response

        #expect(product.recipeCount == 7)
        #expect(tools.first { $0.id == 22 }?.recipeCount == 2)
    }

    @Test func reviewListsProductsWithSuggestedValues() async throws {
        let store = try await OfflineSupport.syncedStore()
        let before = try #require(await store.answer(ProductEndpoints.review())).response
        _ = try await store.answer(ProductEndpoints.confirm(id: 94))
        let after = try #require(await store.answer(ProductEndpoints.review())).response

        #expect(before.total == 37)
        #expect(before.items.map(\.name) == before.items.map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        #expect(after.total == 36)
        #expect(!after.items.contains { $0.id == 94 })
    }

    @Test func searchesProductsByNameAndSortsThem() async throws {
        let store = try await OfflineSupport.syncedStore()
        let found = try #require(await store.answer(ProductEndpoints.search("avo"))).response

        #expect(found.items.map(\.name) == ["Avocado"])
        #expect(try #require(await store.answer(ProductEndpoints.search(""))).response.total == 37)
    }

    @Test func callsThatNeedTheServerAreNotAnswered() async throws {
        let store = try await OfflineSupport.syncedStore()
        let url = try #require(URL(string: "https://example.org/recipe"))
        let week = Week(start: DayDate(year: 2026, month: 11, day: 16))

        #expect(try await store.answer(ImportEndpoints.create(url: url)) == nil)
        #expect(try await store.answer(ImportEndpoints.list) == nil)
        #expect(try await store.answer(ShoppingEndpoints.create(from: week.start, to: week.end)) == nil)
        #expect(try await store.answer(ProductEndpoints.merge(id: 94, into: 95)) == nil)
        #expect(try await store.answer(ToolEndpoints.merge(id: 21, into: 22)) == nil)
        #expect(try await store.answer(ReferenceEndpoints.courses) == nil)
        #expect(await store.pendingCount == 0)
    }

    @Test func remembersAnswersOutsideTheFeed() async throws {
        let directory = OfflineSupport.directory()
        let store = try await OfflineSupport.syncedStore(in: directory)
        await store.remember(try Fixture.data("courses"), forPath: "courses")
        let reopened = OfflineStore(directory: directory)
        let remembered = try #require(await reopened.rememberedAnswer(forPath: "courses"))

        #expect(try ReferenceEndpoints.courses.decode(remembered).count == 9)
        #expect(await reopened.rememberedAnswer(forPath: "imports") == nil)
    }

    @Test func wipingRemovesEverything() async throws {
        let directory = OfflineSupport.directory()
        let store = try await OfflineSupport.syncedStore(in: directory)
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: 39))
        await store.wipe()

        #expect(await !store.hasSynced)
        #expect(await store.pendingCount == 0)
        #expect(await !OfflineStore(directory: directory).hasSynced)
        #expect(await OfflineStore(directory: directory).pendingCount == 0)
    }
}
