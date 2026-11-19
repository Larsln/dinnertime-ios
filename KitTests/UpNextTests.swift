import Foundation
import Testing
@testable import DinnertimeKit

/// The next meal to cook from the plan and whether a day is planned at all.
struct UpNextTests {
    private let today = DayDate(year: 2026, month: 11, day: 19)

    private func entries(_ rows: [(id: Int, date: String, meal: String, cooked: Bool)]) throws -> [MealPlanEntry] {
        let records = rows.map { row in
            let cookedAt = row.cooked ? #""2026-11-19T18:30:00.000000Z""# : "null"
            return #"""
            {"id": \#(row.id), "date": "\#(row.date)", "meal": "\#(row.meal)", "servings": 3, "cooked_at": \#(cookedAt),
            "recipe": {"id": \#(row.id + 100), "title": "Rezept \#(row.id)", "slug": "rezept-\#(row.id)", "servings": 4, "tags": []}}
            """#
        }
        return try MealPlanEndpoints.entries(from: today, to: today).decode(Data(#"{"data": [\#(records.joined(separator: ","))]}"#.utf8))
    }

    @Test func todaysMealsComeInTheOrderTheyAreEaten() throws {
        let plan = try entries([
            (1, "2026-11-19", "snack", false), (2, "2026-11-19", "dinner", false), (3, "2026-11-19", "lunch", false),
            (4, "2026-11-19", "dessert", false), (5, "2026-11-19", "breakfast", true), (6, "2026-11-20", "breakfast", false),
        ])

        #expect(plan.nextMeal(from: today)?.id == 3)
        #expect(plan.filter { $0.id != 3 }.nextMeal(from: today)?.id == 2)
        #expect(plan.filter { ![2, 3].contains($0.id) }.nextMeal(from: today)?.id == 4)
        #expect(plan.filter { $0.id == 1 || $0.id == 6 }.nextMeal(from: today)?.id == 1)
    }

    @Test func withoutAnOpenMealTodayTheNearestLaterDayCounts() throws {
        let plan = try entries([
            (1, "2026-11-19", "dinner", true), (2, "2026-11-23", "lunch", false),
            (3, "2026-11-21", "dinner", false), (4, "2026-11-21", "breakfast", false), (5, "2026-12-01", "breakfast", false),
        ])

        #expect(plan.nextMeal(from: today)?.id == 4)
        #expect(plan.nextMeal(from: today)?.servings == 3)
    }

    @Test func pastDaysAndCookedMealsNeverCount() throws {
        let plan = try entries([(1, "2026-11-18", "dinner", false), (2, "2026-11-19", "dinner", true), (3, "2026-11-20", "lunch", true)])

        #expect(plan.nextMeal(from: today) == nil)
        #expect([MealPlanEntry]().nextMeal(from: today) == nil)
    }

    @Test func aMealOfTodayStaysUntilItIsCooked() throws {
        let open = try entries([(1, "2026-11-19", "dinner", false), (2, "2026-11-20", "breakfast", false)])
        let cooked = try entries([(1, "2026-11-19", "dinner", true), (2, "2026-11-20", "breakfast", false)])

        #expect(open.nextMeal(from: today)?.id == 1)
        #expect(cooked.nextMeal(from: today)?.id == 2)
    }

    @Test func twoMealsOfTheSameSlotKeepTheOrderOfTheirIds() throws {
        let plan = try entries([(9, "2026-11-19", "dinner", false), (4, "2026-11-19", "dinner", false)])

        #expect(plan.nextMeal(from: today)?.id == 4)
    }

    @Test func aDayIsPlannedWithAnyEntryCookedOrNot() throws {
        let plan = try entries([(1, "2026-11-19", "lunch", true), (2, "2026-11-21", "dinner", false)])

        #expect(plan.isPlanned(on: today))
        #expect(!plan.isPlanned(on: today.adding(days: 1)))
        #expect(plan.isPlanned(on: today.adding(days: 2)))
        #expect(![MealPlanEntry]().isPlanned(on: today))
    }

    @Test func countsTheDaysBetweenTwoDays() {
        #expect(today.days(since: today) == 0)
        #expect(today.adding(days: 1).days(since: today) == 1)
        #expect(DayDate(year: 2026, month: 12, day: 1).days(since: today) == 12)
        #expect(DayDate(year: 2027, month: 1, day: 1).days(since: DayDate(year: 2026, month: 12, day: 31)) == 1)
        #expect(today.days(since: today.adding(days: 3)) == -3)
        #expect(DayDate(year: 2026, month: 3, day: 30).days(since: DayDate(year: 2026, month: 3, day: 28)) == 2)
    }

    @Test func thePlanOfTheCopyAnswersWithoutAConnection() async throws {
        let store = try await OfflineSupport.syncedStore()
        let all = try #require(await store.answer(MealPlanEndpoints.entries(from: DayDate(year: 2000, month: 1, day: 1), to: DayDate(year: 2100, month: 1, day: 1)))).response
        let first = try #require(all.min { $0.date < $1.date })
        let next = try #require(all.nextMeal(from: first.date))
        let cooked = try #require(await store.answer(MealPlanEndpoints.setCooked(true, id: next.id)))
        let after = try #require(await store.answer(MealPlanEndpoints.entries(from: first.date, to: DayDate(year: 2100, month: 1, day: 1)))).response

        #expect(!next.isCooked)
        #expect(cooked.areas.contains(.plan))
        #expect(after.nextMeal(from: first.date)?.id != next.id)
    }
}
