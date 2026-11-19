import DinnertimeKit
import Observation

/// Today's dinner round with everything a member can do in it; all of it needs the server.
@MainActor
@Observable
final class DinnerRoundModel: ErrorReporting {
    var errorMessage: String?
    /// The round of today that is not closed.
    private(set) var round: DinnerRound?
    /// Whether the server said at least once whether a round is running.
    private(set) var hasLoaded = false
    /// Whether a vote or another change is on its way to the server.
    private(set) var isBusy = false

    /// Ids of the recipes turned down in the second look; the server already holds those votes.
    private var declined: Set<Int> = []
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Where the signed-in user stands in the round.
    var phase: DinnerPhase {
        round.phase(declined: declined)
    }

    /// The card to decide on with its place in the pass that is running.
    var deck: DinnerDeckPosition? {
        round?.deck(declined: declined)
    }

    /// Asks the server for the round; without an answer, and while a change is on its way, what is shown stays.
    func load() async {
        guard !isBusy else {
            return
        }
        do {
            let current = try await session.send(DinnerRoundEndpoints.current)
            if !isBusy {
                show(current)
                hasLoaded = true
            }
        } catch {
            return
        }
    }

    /// Starts a round, or joins the one that is running; returns whether the server accepted it.
    func start(_ options: DinnerRoundOptions) async -> Bool {
        await change {
            show(try await session.send(DinnerRoundEndpoints.start(options)))
            hasLoaded = true
        }
    }

    /// Says yes or no to the card that is shown; a no in the second look is remembered here.
    func decide(liked: Bool) async {
        guard let round, let card = deck?.card, !isBusy else {
            return
        }
        let isSecondLook = phase == .second
        await change {
            let next = try await session.send(DinnerRoundEndpoints.vote(liked: liked, recipeID: card.recipe.id, roundID: round.id))
            if isSecondLook, !liked {
                declined.insert(card.recipe.id)
            }
            show(next)
        }
    }

    /// Plans the match as today's dinner, which closes the round; `nil` when the server refused.
    func plan() async -> MealPlanEntry? {
        guard let round else {
            return nil
        }
        var entry: MealPlanEntry?
        await change {
            entry = try await session.send(DinnerRoundEndpoints.plan(roundID: round.id))
            show(nil)
        }
        return entry
    }

    /// Closes the round for everyone without planning anything; returns whether the server accepted it.
    func close() async -> Bool {
        guard let round else {
            return true
        }
        return await change {
            try await session.send(DinnerRoundEndpoints.close(roundID: round.id))
            show(nil)
        }
    }

    /// Runs a change; after a failure the round is read again, because it may have moved on.
    @discardableResult
    private func change(_ operation: () async throws -> Void) async -> Bool {
        isBusy = true
        let isDone = await attempt(operation)
        isBusy = false
        if !isDone {
            await load()
        }
        return isDone
    }

    private func show(_ next: DinnerRound?) {
        if next?.id != round?.id {
            declined = []
        }
        round = next
    }
}
