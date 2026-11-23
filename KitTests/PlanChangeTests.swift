import Foundation
import Testing
@testable import DinnertimeKit

/// Why meals go together, changes to the plan, and products bought as others.
struct PlanChangeTests {
    private let english = AmountFormatter(locale: Locale(identifier: "en_US"))

    @Test func decodesTheReasonsOfSavedEntries() throws {
        let json = #"""
        {"data": [{"entry_id": 4, "reasons": [
            {"type": "shares", "products": ["Sahne"], "with": [{"title": "Suppe", "date": "2026-11-18"}]},
            {"type": "pantry", "products": ["Spinat"]},
            {"type": "favorite"},
            {"type": "rating", "value": 8.5},
            {"type": "last_planned", "days": 12},
            {"type": "not_recent"},
            {"type": "quick", "minutes": null},
            {"type": "spicy"}
        ]}]}
        """#
        let from = DayDate(year: 2026, month: 11, day: 16)
        let answer = try MealPlanEndpoints.reasons(from: from, to: from.adding(days: 6)).decode(Data(json.utf8))

        #expect(answer.first?.entryID == 4)
        #expect(answer.first?.reasons == [
            .shares(products: ["Sahne"], partners: [PlanReason.Partner(title: "Suppe", date: DayDate(year: 2026, month: 11, day: 18))]),
            .pantry(products: ["Spinat"]),
            .favorite,
            .rating(8.5),
            .lastPlanned(days: 12),
            .notRecent,
            .quick(minutes: nil),
            .unknown,
        ])
    }

    @Test func variantsShareTheItemOfTheProductTheyAreBoughtAs() throws {
        let json = #"""
        {"data": {"id": 9, "label": null, "is_manual": false, "needed_amount": null, "purchase_amount": null,
        "packages": [], "extra_amounts": [], "uses": [],
        "variants": [{"product_id": 3, "name": "Gurkenwasser", "base_unit": "ml", "needed_amount": 50, "purchase_amount": 50,
            "packages": [], "leftover_amount": 0, "wasted_amount": 0, "extra_amounts": [],
            "uses": [{"date": "2026-11-16", "recipe_id": 1, "title": "Salat", "amount": 50}]}],
        "product": {"id": 2, "name": "Saure Gurken", "plural_name": null, "base_unit": "g", "status": "confirmed",
            "buy_as": null}}}
        """#
        let item = try ShoppingEndpoints.setChecked(true, itemID: 9).decode(Data(json.utf8))

        #expect(!item.hasOwnAmounts)
        #expect(item.variants.map(\.name) == ["Gurkenwasser"])
        #expect(item.variants.first?.uses.map(\.title) == ["Salat"])
        #expect(item.purchaseText(formatter: english) == nil)
        #expect(item.shortPurchaseText(formatter: english) == "50 ml")
        #expect(item.variantNamesText == nil)
    }

    @Test func requestsMoveEntriesAndThePlan() throws {
        let builder = RequestBuilder(baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!), token: "secret", languages: ["en-US"])
        let day = DayDate(year: 2026, month: 11, day: 19)
        let update = try builder.request(for: MealPlanEndpoints.update(id: 5, date: day, meal: .lunch, recipeID: 7, servings: 4))
        let shift = try builder.request(for: MealPlanEndpoints.shift(from: day, days: -1))
        let body = { (request: URLRequest) in try JSONSerialization.jsonObject(with: request.httpBody ?? Data()) as? [String: Any] ?? [:] }

        #expect(update.httpMethod == "PATCH")
        #expect(try body(update)["recipe_id"] as? Int == 7)
        #expect(try body(update)["date"] as? String == "2026-11-19")
        #expect(shift.url?.path() == "/api/v1/meal-plan/shift")
        #expect(try body(shift)["days"] as? Int == -1)
    }

    @Test func theCopyMovesThePlanFromADayOn() async throws {
        let store = try await OfflineSupport.syncedStore()
        let from = DayDate(year: 2026, month: 11, day: 18)

        let moved = try #require(await store.answer(MealPlanEndpoints.shift(from: from.adding(days: 2), days: 1))).response
        let entries = try #require(await store.answer(MealPlanEndpoints.entries(from: from, to: from.adding(days: 6)))).response

        #expect(moved.map(\.id) == [23, 24])
        #expect(entries.map(\.date.description) == ["2026-11-18", "2026-11-19", "2026-11-21", "2026-11-22"])
    }

    @Test func theCopyRemembersWhatAProductIsBoughtAs() async throws {
        let store = try await OfflineSupport.syncedStore()
        let lime = try #require(await store.answer(ProductEndpoints.detail(id: 97))).response
        var input = ProductInput(name: lime.name, icon: lime.icon, storeSectionID: lime.storeSection?.id, baseUnit: lime.baseUnit, isPantryStaple: false, shelfLifeOpenedDays: nil)
        input.buyAsID = 75

        let changed = try #require(await store.answer(ProductEndpoints.update(id: 97, input))).response

        #expect(changed.buyAs == ProductReference(id: 75, name: "Zwiebel"))
    }
}
