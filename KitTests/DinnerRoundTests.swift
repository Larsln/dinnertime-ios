import Foundation
import Testing
@testable import DinnertimeKit

/// Dinner rounds: decoding, requests, where a member stands and that they stay out of the local copy.
struct DinnerRoundTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func card(_ id: Int, vote: Bool? = nil, liked: Bool = false, missing: Int = 0) -> String {
        let vote = vote.map(String.init) ?? "null"
        return #"""
        {"recipe": {"id": \#(id), "title": "Rezept \#(id)", "slug": "rezept-\#(id)", "prep_minutes": 10, "cook_minutes": 15, "tags": []},
        "missing_count": \#(missing), "my_vote": \#(vote), "liked_by_others": \#(liked)}
        """#
    }

    private func round(status: String = "voting", cards: [String], match: Int? = nil, members: String = "[]") throws -> DinnerRound {
        let match = match.map { #"{"id": \#($0), "title": "Rezept \#($0)", "slug": "rezept-\#($0)", "tags": []}"# } ?? "null"
        let json = #"""
        {"data": {"id": 7, "date": "2026-11-19", "is_solo": false, "status": "\#(status)", "match": \#(match),
        "cards": [\#(cards.joined(separator: ","))], "members": \#(members)}}
        """#
        return try DinnerRoundEndpoints.start(DinnerRoundOptions()).decode(Data(json.utf8))
    }

    @Test func readsARoundAndThatNoneIsRunning() throws {
        let members = #"[{"name": "Lars", "voted_count": 2}, {"name": "Anna", "voted_count": 1}]"#
        let round = try round(cards: [card(1, vote: true, missing: 2), card(2, vote: false), card(3)], members: members)
        let none = try DinnerRoundEndpoints.current.decode(Data(#"{"data": null}"#.utf8))

        #expect(round.id == 7)
        #expect(round.date == DayDate(year: 2026, month: 11, day: 19))
        #expect(!round.isSolo)
        #expect(round.status == .voting)
        #expect(round.match == nil)
        #expect(round.cards.map(\.recipe.id) == [1, 2, 3])
        #expect(round.cards.map(\.missingCount) == [2, 0, 0])
        #expect(round.cards.map(\.myVote) == [true, false, nil])
        #expect(round.members.map(\.votedCount) == [2, 1])
        #expect(round.membersBehind == ["Lars", "Anna"])
        #expect(none == nil)
    }

    @Test func asksForStartsVotesPlansAndCloses() throws {
        let current = try builder.request(for: DinnerRoundEndpoints.current)
        let plain = try builder.request(for: DinnerRoundEndpoints.start(DinnerRoundOptions()))
        let limited = try builder.request(for: DinnerRoundEndpoints.start(DinnerRoundOptions(isSolo: true, onlyAvailable: true, maxMinutes: DinnerRoundOptions.quickMinutes)))
        let vote = try builder.request(for: DinnerRoundEndpoints.vote(liked: true, recipeID: 12, roundID: 7))
        let plan = try builder.request(for: DinnerRoundEndpoints.plan(roundID: 7))
        let close = try builder.request(for: DinnerRoundEndpoints.close(roundID: 7))

        #expect(current.httpMethod == "GET")
        #expect(current.url?.path() == "/api/v1/dinner-rounds/current")
        #expect(plain.httpMethod == "POST")
        #expect(plain.url?.path() == "/api/v1/dinner-rounds")
        #expect(try json(plain) as NSDictionary == ["is_solo": false, "only_available": false])
        #expect(try json(limited) as NSDictionary == ["is_solo": true, "only_available": true, "max_minutes": 30])
        #expect(vote.httpMethod == "POST")
        #expect(vote.url?.path() == "/api/v1/dinner-rounds/7/votes")
        #expect(try json(vote) as NSDictionary == ["recipe_id": 12, "liked": true])
        #expect(plan.httpMethod == "POST")
        #expect(plan.url?.path() == "/api/v1/dinner-rounds/7/plan")
        #expect(plan.httpBody == nil)
        #expect(close.httpMethod == "DELETE")
        #expect(close.url?.path() == "/api/v1/dinner-rounds/7")
    }

    @Test func aMemberVotesUntilNoCardIsLeftAndThenWaits() throws {
        let fresh = try round(cards: [card(1), card(2), card(3)])
        let midway = try round(cards: [card(1, vote: false), card(2), card(3)])
        let through = try round(cards: [card(1, vote: false), card(2, vote: true), card(3, vote: false)], members: #"[{"name": "Lars", "voted_count": 3}, {"name": "Anna", "voted_count": 1}]"#)

        #expect(fresh.phase() == .voting)
        #expect(fresh.deck() == DinnerDeckPosition(card: fresh.cards[0], position: 1, total: 3))
        #expect(midway.deck()?.card.recipe.id == 2)
        #expect(midway.deck()?.position == 2)
        #expect(through.phase() == .waiting)
        #expect(through.deck() == nil)
        #expect(through.membersBehind == ["Anna"])
        #expect(DinnerPhase.waiting.isPolled)
        #expect(!DinnerPhase.voting.isPolled)
    }

    @Test func aMatchAndAnEmptyRoundComeBeforeEverythingElse() throws {
        let matched = try round(status: "matched", cards: [card(1, vote: true), card(2)], match: 1)
        let empty = try round(cards: [])
        let none: DinnerRound? = nil

        #expect(matched.phase() == .matched)
        #expect(matched.match?.id == 1)
        #expect(empty.phase() == .empty)
        #expect(empty.deck() == nil)
        #expect(none.phase() == .none)
        #expect(Optional(matched).phase() == .matched)
    }

    @Test func anUndecidedRoundShowsWhatTheOthersLikedASecondTime() throws {
        let undecided = try round(status: "undecided", cards: [card(1, vote: false, liked: true), card(2, vote: true), card(3, vote: false, liked: true)])
        let nothingLiked = try round(status: "undecided", cards: [card(1, vote: false), card(2, vote: true)])

        #expect(undecided.phase() == .second)
        #expect(undecided.deck() == DinnerDeckPosition(card: undecided.cards[0], position: 1, total: 2))
        #expect(undecided.deck(declined: [1]) == DinnerDeckPosition(card: undecided.cards[2], position: 2, total: 2))
        #expect(undecided.phase(declined: [1]) == .second)
        #expect(undecided.phase(declined: [1, 3]) == .exhausted)
        #expect(undecided.deck(declined: [1, 3]) == nil)
        #expect(nothingLiked.phase() == .exhausted)
        #expect(DinnerPhase.second.isVoting && DinnerPhase.second.isPolled)
        #expect(DinnerPhase.exhausted.isPolled && !DinnerPhase.exhausted.isVoting)
    }

    @Test func theAreaOfTheRoundsIsAnnouncedButNotSynced() {
        let areas = RealtimeArea.areas(in: ServerSentEvent(name: nil, data: #"{"areas": ["dinner", "plan", "unknown"]}"#))

        #expect(areas == [.dinner, .plan])
        #expect(!RealtimeArea.dinner.isSynced)
        #expect(RealtimeArea.allCases.filter { !$0.isSynced } == [.dinner])
    }

    @Test func roundsAreNeverAnsweredFromTheCopyNorQueued() async throws {
        let store = try await OfflineSupport.syncedStore()

        #expect(try await store.answer(DinnerRoundEndpoints.current) == nil)
        #expect(try await store.answer(DinnerRoundEndpoints.start(DinnerRoundOptions())) == nil)
        #expect(try await store.answer(DinnerRoundEndpoints.vote(liked: true, recipeID: 98, roundID: 7)) == nil)
        #expect(try await store.answer(DinnerRoundEndpoints.plan(roundID: 7)) == nil)
        #expect(try await store.answer(DinnerRoundEndpoints.close(roundID: 7)) == nil)
        #expect(await store.pendingCount == 0)
    }
}
