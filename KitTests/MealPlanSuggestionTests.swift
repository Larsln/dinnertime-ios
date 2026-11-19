import Foundation
import Testing
@testable import DinnertimeKit

/// Requests of the planner and the keeping and avoiding of proposals.
struct MealPlanSuggestionTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )
    private let monday = MealSlot(date: DayDate(year: 2026, month: 12, day: 7), meal: .dinner)
    private let tuesday = MealSlot(date: DayDate(year: 2026, month: 12, day: 8), meal: .lunch)

    private var criteria: MealPlanCriteria {
        MealPlanCriteria(from: monday.date, to: DayDate(year: 2026, month: 12, day: 13), servings: 2, slots: [monday, tuesday])
    }

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func suggestions(_ recipes: [(MealSlot, Int)], candidates: Int = 8) throws -> MealSuggestions {
        let rows = recipes.map { slot, id in
            #"{"date": "\#(slot.date)", "meal": "\#(slot.meal.rawValue)", "kept": false, "recipe": {"id": \#(id), "title": "R\#(id)", "slug": "r\#(id)", "tags": []}}"#
        }
        let text = #"{"data": [\#(rows.joined(separator: ","))], "meta": {"candidate_count": \#(candidates)}}"#
        return try MealPlanEndpoints.suggest(MealPlanSuggestionRequest(criteria)).decode(Data(text.utf8))
    }

    private func board() throws -> ProposalBoard {
        var board = ProposalBoard()
        board.show(try suggestions([(monday, 4), (tuesday, 5)]))
        return board
    }

    @Test func decodesSuggestions() throws {
        let answer = try MealPlanEndpoints.suggest(MealPlanSuggestionRequest(criteria)).decode(Fixture.data("suggestions"))

        #expect(answer.candidateCount == 8)
        #expect(answer.proposals.map(\.slot) == [monday, tuesday])
        #expect(answer.proposals.map(\.kept) == [false, true])
        #expect(answer.proposals[0].recipe.title == "Hähnchen-Kokos-Curry")
        #expect(answer.proposals[1].assignment == MealAssignment(date: tuesday.date, meal: .lunch, recipeID: 5))
    }

    @Test func firstRequestLeavesOutEmptyLists() throws {
        let request = try builder.request(for: MealPlanEndpoints.suggest(ProposalBoard().request(for: criteria)))
        let body = try json(request)

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/v1/meal-plan/suggest")
        #expect(body["from"] as? String == "2026-12-07")
        #expect(body["to"] as? String == "2026-12-13")
        #expect(body["servings"] as? Int == 2)
        #expect(body["slots"] as? [[String: String]] == [["date": "2026-12-07", "meal": "dinner"], ["date": "2026-12-08", "meal": "lunch"]])
        #expect(body["preferences"] as? [String: Bool] == [
            "use_leftovers": true, "quick_on_weekdays": false, "prefer_not_recent": true, "prefer_favorites": false, "variety": true,
        ])
        for key in ["tag_ids", "courses", "keep", "avoid"] {
            #expect(body[key] == nil, "\(key) is sent")
        }
    }

    @Test func sendsRestrictionsAndChangedPreferences() throws {
        var criteria = criteria
        criteria.tagIDs = [16, 22]
        criteria.courses = ["main", "soup"]
        criteria.preferences.quickOnWeekdays = true
        criteria.preferences.variety = false
        let body = try json(builder.request(for: MealPlanEndpoints.suggest(MealPlanSuggestionRequest(criteria))))
        let preferences = try #require(body["preferences"] as? [String: Bool])

        #expect(body["tag_ids"] as? [Int] == [16, 22])
        #expect(body["courses"] as? [String] == ["main", "soup"])
        #expect(preferences["quick_on_weekdays"] == true)
        #expect(preferences["variety"] == false)
    }

    @Test func rerollingAllKeepsOnlyLockedProposals() throws {
        var board = try board()
        board.toggleLock(tuesday)
        let request = board.request(for: criteria)

        #expect(board.isLocked(tuesday))
        #expect(request.keep == [MealAssignment(date: tuesday.date, meal: .lunch, recipeID: 5)])
        #expect(request.avoid == nil)
    }

    @Test func locksOfSlotsThatAreNoLongerWantedAreNotSent() throws {
        var board = try board()
        board.toggleLock(tuesday)
        var criteria = criteria
        criteria.slots = [monday]

        #expect(board.request(for: criteria).keep == nil)
    }

    @Test func rerollingOneSlotKeepsTheOthersAndAvoidsItsRecipe() throws {
        let request = try board().request(for: criteria, rerolling: monday)
        let body = try json(builder.request(for: MealPlanEndpoints.suggest(request)))

        #expect(request.keep == [MealAssignment(date: tuesday.date, meal: .lunch, recipeID: 5)])
        #expect(request.avoid == [MealAssignment(date: monday.date, meal: .dinner, recipeID: 4)])
        #expect(body["keep"] as? [[String: AnyHashable]] == [["date": "2026-12-08", "meal": "lunch", "recipe_id": 5]])
        #expect(body["avoid"] as? [[String: AnyHashable]] == [["date": "2026-12-07", "meal": "dinner", "recipe_id": 4]])
    }

    @Test func repeatedRerollsAvoidEveryRecipeTheSlotWasOffered() throws {
        var board = try board()
        board.show(try suggestions([(monday, 7), (tuesday, 5)], candidates: 6), rerolling: monday)
        let request = board.request(for: criteria, rerolling: monday)

        #expect(board.proposals.map(\.recipe.id) == [7, 5])
        #expect(board.candidateCount == 6)
        #expect(request.avoid?.map(\.recipeID) == [4, 7])
    }

    @Test func rerollWithoutAnotherRecipeKeepsTheProposalAndStartsOver() throws {
        var board = try board()
        board.show(try suggestions([(monday, 7), (tuesday, 5)]), rerolling: monday)
        board.show(try suggestions([(tuesday, 5)]), rerolling: monday)

        #expect(board.proposals.map(\.recipe.id) == [7, 5])
        #expect(board.request(for: criteria, rerolling: monday).avoid?.map(\.recipeID) == [7])
    }

    @Test func newSuggestionsEndLocksOfMissingSlots() throws {
        var board = try board()
        board.toggleLock(monday)
        board.toggleLock(tuesday)
        board.show(try suggestions([(tuesday, 5)]))

        #expect(!board.isLocked(monday))
        #expect(board.isLocked(tuesday))
        board.toggleLock(tuesday)
        #expect(!board.isLocked(tuesday))
    }

    @Test func savesProposalsAsBatch() throws {
        let request = try builder.request(for: MealPlanEndpoints.save(try board().entries(servings: 3)))
        let body = try json(request)

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/v1/meal-plan/batch")
        #expect(body["entries"] as? [[String: AnyHashable]] == [
            ["date": "2026-12-07", "meal": "dinner", "recipe_id": 4, "servings": 3],
            ["date": "2026-12-08", "meal": "lunch", "recipe_id": 5, "servings": 3],
        ])
    }
}
