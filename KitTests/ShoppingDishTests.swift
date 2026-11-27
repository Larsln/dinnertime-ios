import Foundation
import Testing
@testable import DinnertimeKit

/// What a shopping list tells beyond its positions: the needs the stock covers and the meals it was made for.
struct ShoppingDishTests {
    private static let week = (from: DayDate(year: 2026, month: 11, day: 16), to: DayDate(year: 2026, month: 11, day: 22))

    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    /// The recorded list with needs the stock covers, as a page of the feed.
    private func pageWithStock() throws -> Data {
        let feed = try #require(JSONSerialization.jsonObject(with: OfflineSupport.feed()) as? [String: Any])
        let data = try #require(feed["data"] as? [String: Any])
        let changed = try #require(data["changed"] as? [String: Any])
        var list = try #require((changed["shopping_lists"] as? [[String: Any]])?.first)
        list["in_stock"] = [
            [
                "product_id": 900, "name": "Reis", "base_unit": "g", "needed_amount": 150, "is_staple": false,
                "uses": [["date": "2026-11-18", "recipe_id": 98, "title": "Hummus", "amount": 150]],
            ],
            [
                "product_id": 902, "name": "Wasser", "base_unit": "ml", "needed_amount": 100, "is_staple": false,
                "uses": [["date": "2026-11-18", "recipe_id": 98, "title": "Hummus", "amount": 100]],
            ],
            [
                "product_id": 901, "name": "Salz", "base_unit": "g", "needed_amount": NSNull(), "is_staple": true,
                "uses": [["date": "2026-11-18", "recipe_id": 98, "title": "Hummus", "amount": NSNull()]],
            ],
        ]
        return try OfflineSupport.page(version: 127, changed: ["shopping_lists": [list]])
    }

    @Test func aListWithoutStockedNeedsDecodesAsEmpty() async throws {
        let store = try await OfflineSupport.syncedStore()
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(list.inStock.isEmpty)
    }

    @Test func theLocalCopyKeepsWhatTheStockCovers() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.applySync(pageWithStock())
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let formatter = AmountFormatter(locale: Locale(identifier: "en_US"))

        #expect(list.inStock.map { $0.text(formatter: formatter) } == ["Reis 150 g", "Wasser 100 ml", "Salz"])
        #expect(list.inStock.map(\.isStaple) == [false, false, true])
        #expect(list.inStock[2].uses.first?.amount == nil)
    }

    @Test func mealsNameWhatTheListHoldsForThem() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.applySync(pageWithStock())
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let entries = try #require(await store.answer(MealPlanEndpoints.entries(from: Self.week.from, to: Self.week.to))).response
        let dishes = list.dishes(from: entries)
        let hummus = try #require(dishes.first)

        #expect(dishes.map(\.entry.recipe.title) == ["Hummus", "Crispy Chicken Tacos", "Nudeln mit Hackfleisch und Käse", "Guacamole"])
        #expect(hummus.ingredients.map(\.name) == ["Knoblauchzehe", "Wasser", "Kichererbsen", "Reis", "Salz"])
        #expect(hummus.ingredients.map(\.source) == [.open, .open, .settled, .stock, .stock])
        #expect(hummus.ingredients.map(\.amount) == [15, 1320, 200, 150, nil])
        #expect(dishes[1].ingredients.contains { $0.source == .stock } == false)
    }

    @Test func mealsOutsideThePeriodAreLeftOut() async throws {
        let store = try await OfflineSupport.syncedStore()
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(list.covers(Self.week.from) && list.covers(Self.week.to))
        #expect(!list.covers(Self.week.to.adding(days: 1)))
        #expect(!list.covers(Self.week.from.adding(days: -1)))
    }

    @Test func theNoteOfStockedNeedsIsSwitchedOnAloneAndOffline() async throws {
        let request = try builder.request(for: HouseholdSettingsEndpoints.setShowStockedNeeds(true))
        let body = try JSONSerialization.jsonObject(with: #require(request.httpBody)) as? NSDictionary
        let silent = try HouseholdSettingsEndpoints.settings.decode(Data(#"{"data":{"default_servings":4}}"#.utf8))
        let store = try await OfflineSupport.syncedStore()
        let changed = try #require(await store.answer(HouseholdSettingsEndpoints.setShowStockedNeeds(true))).response

        #expect(body == ["show_stocked_needs": true])
        #expect(!silent.showStockedNeeds)
        #expect(changed.showStockedNeeds)
        #expect(changed.defaultServings == 2)
        #expect(try #require(await store.answer(HouseholdSettingsEndpoints.settings)).response.showStockedNeeds)
    }
}
