import Foundation
import Testing
@testable import DinnertimeKit

/// Who eats a planned meal, the portions cooked for them and what they said about their portion.
struct PortionTests {
    private let day = DayDate(year: 2026, month: 11, day: 18)

    private func entry(_ store: OfflineStore, id: Int) async throws -> MealPlanEntry {
        let entries = try #require(await store.answer(MealPlanEndpoints.entries(from: day.adding(days: -7), to: day.adding(days: 7)))).response
        return try #require(entries.first { $0.id == id })
    }

    /// The recorded entry with members who eat, as a page of the feed.
    private func pageWithEaters() throws -> Data {
        let feed = try #require(JSONSerialization.jsonObject(with: OfflineSupport.feed()) as? [String: Any])
        let data = try #require(feed["data"] as? [String: Any])
        let changed = try #require(data["changed"] as? [String: Any])
        var entry = try #require((changed["meal_plan_entries"] as? [[String: Any]])?.first { $0["id"] as? Int == 21 })
        entry["servings"] = 3
        entry["portions"] = 3.02
        entry["guests"] = 1
        entry["eaters"] = [["user_id": 1, "name": "Anna", "factor": 1.15], ["user_id": 2, "name": NSNull(), "factor": 0.87]]
        entry["portion_feedback"] = [["user_id": 2, "verdict": "too_big"]]
        return try OfflineSupport.page(version: 127, changed: ["meal_plan_entries": [entry]])
    }

    @Test func entriesWithoutPortionsCookTheirServings() async throws {
        let store = try await OfflineSupport.syncedStore()
        let entry = try await entry(store, id: 21)

        #expect(entry.portions == 2)
        #expect(entry.guests == 0)
        #expect(entry.eaters == nil)
        #expect(entry.portionFeedback.isEmpty)
        #expect(entry.wholePortions == 2)
        #expect(entry.portionsText(locale: Locale(identifier: "de_DE")) == "2")
    }

    @Test func eatersPortionsAndVerdictsAreDecoded() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.applySync(pageWithEaters())
        let entry = try await entry(store, id: 21)

        #expect(entry.servings == 3)
        #expect(entry.portions == 3.02)
        #expect(entry.guests == 1)
        #expect(entry.eaters?.map(\.userID) == [1, 2])
        #expect(entry.eaters?.map(\.name) == ["Anna", nil])
        #expect(entry.eaters?.map(\.factor) == [1.15, 0.87])
        #expect(entry.verdict(of: 2) == .tooBig)
        #expect(entry.verdict(of: 1) == nil)
        #expect(entry.wholePortions == nil)
        #expect(entry.portionsText(locale: Locale(identifier: "de_DE")) == "3,02")
    }

    @Test func theMembersOfTheHouseholdAreDecoded() throws {
        let json = #"{"data": {"default_servings": 2, "currency": "EUR", "members": [{"id": 1, "name": "Anna"}, {"id": 2, "name": "Ben"}]}}"#
        let settings = try HouseholdSettingsEndpoints.settings.decode(Data(json.utf8))
        let old = try HouseholdSettingsEndpoints.settings.decode(Data(#"{"data": {"default_servings": 2}}"#.utf8))

        #expect(settings.members.map(\.name) == ["Anna", "Ben"])
        #expect(old.members.isEmpty)
    }

    @Test func whoEatsSetsServingsAndPortionsOffline() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.applySync(pageWithEaters())
        let changed = try #require(await store.answer(MealPlanEndpoints.update(id: 21, date: day, meal: .dinner, recipeID: 98, eaterIDs: [1, 3], guests: 2))).response
        let created = try #require(await store.answer(MealPlanEndpoints.create(date: day, meal: .lunch, recipeID: 98, eaterIDs: [], guests: 4))).response
        let sent = try #require(await store.pendingChanges.first?.body.flatMap { try? JSONValue.object(from: $0) })

        #expect(changed.servings == 4)
        #expect(changed.guests == 2)
        #expect(changed.eaters?.map(\.factor) == [1.15, 1])
        #expect(changed.portions == 4.15)
        #expect(created.servings == 4)
        #expect(created.portions == 4)
        #expect(created.eaters == [])
        #expect(sent["eater_ids"] as? [Int] == [1, 3])
        #expect(sent["guests"] as? Int == 2)
        #expect(sent["servings"] == nil)
    }

    @Test func movingAnEntryKeepsWhoEats() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.applySync(pageWithEaters())
        let moved = try #require(await store.answer(MealPlanEndpoints.update(id: 21, date: day.adding(days: 1), meal: .dinner, recipeID: 98, servings: 3))).response

        #expect(moved.date == day.adding(days: 1))
        #expect(moved.portions == 3.02)
        #expect(moved.eaters?.count == 2)
    }

    @Test func aVerdictIsMirroredAndQueuedOffline() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.applySync(pageWithEaters())
        let judged = try #require(await store.answer(MealPlanEndpoints.setPortionVerdict(.tooSmall, id: 21, userID: 1))).response
        let entry = try #require(await store.pendingChanges.last)
        let body = try #require(entry.body.flatMap { try? JSONValue.object(from: $0) })

        #expect(judged.verdict(of: 1) == .tooSmall)
        #expect(judged.verdict(of: 2) == .tooBig)
        #expect(entry.method == .put)
        #expect(entry.path == "meal-plan/21/portion-feedback")
        #expect(body["verdict"] as? String == "too_small")

        let withdrawn = try #require(await store.answer(MealPlanEndpoints.setPortionVerdict(nil, id: 21, userID: 1))).response
        let last = try #require(await store.pendingChanges.last?.body.flatMap { try? JSONValue.object(from: $0) })

        #expect(withdrawn.verdict(of: 1) == nil)
        #expect(last["verdict"] is NSNull)
    }
}
