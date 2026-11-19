import Foundation

/// The rounds in which the household decides together what to cook tonight; they need the server.
public enum DinnerRoundEndpoints {
    private struct VoteBody: Encodable {
        let recipeId: Int
        let liked: Bool
    }

    /// `GET /dinner-rounds/current`: the round of today that is not closed, or `nil`.
    public static var current: Endpoint<DinnerRound?> {
        .resource(.get, "dinner-rounds/current")
    }

    /// `POST /dinner-rounds`: starts a round, or answers with the one that is running.
    public static func start(_ options: DinnerRoundOptions) -> Endpoint<DinnerRound> {
        .resource(.post, "dinner-rounds", body: options)
    }

    /// `POST /dinner-rounds/{id}/votes`: says yes or no to a recipe; answers `409` once the round has a match.
    public static func vote(liked: Bool, recipeID: Int, roundID: Int) -> Endpoint<DinnerRound> {
        .resource(.post, "dinner-rounds/\(roundID)/votes", body: VoteBody(recipeId: recipeID, liked: liked))
    }

    /// `POST /dinner-rounds/{id}/plan`: plans the match as today's dinner and closes the round.
    public static func plan(roundID: Int) -> Endpoint<MealPlanEntry> {
        .resource(.post, "dinner-rounds/\(roundID)/plan")
    }

    /// `DELETE /dinner-rounds/{id}`: closes the round without planning anything.
    public static func close(roundID: Int) -> Endpoint<Void> {
        .empty(.delete, "dinner-rounds/\(roundID)")
    }
}
