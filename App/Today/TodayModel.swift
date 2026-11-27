import DinnertimeKit
import Foundation
import Observation

/// What matters today: the plan of the coming two weeks, from which the next meal to cook is taken,
/// and the round that decides tonight's dinner while nothing is planned for today.
@MainActor
@Observable
final class TodayModel {
    private static let daysAhead = 13

    /// The day the plan was last read on.
    private(set) var today = DayDate(.now)
    /// The entries from today on; `nil` until they were read.
    private(set) var entries: [MealPlanEntry]?

    let dinner: DinnerRoundModel

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
        dinner = DinnerRoundModel(session: session)
    }

    /// The next meal to cook that is not cooked yet.
    var upNext: MealPlanEntry? {
        entries?.nextMeal(from: today)
    }

    /// The sides served with the next meal to cook.
    var upNextSides: [MealPlanEntry] {
        upNext.map { entries?.sides(of: $0) ?? [] } ?? []
    }

    /// Whether the plan is known and holds nothing for today, cooked or not.
    var isTodayOpen: Bool {
        entries.map { !$0.isPlanned(on: today) } ?? false
    }

    /// Reads the plan from the local copy; on failure what is shown stays.
    func load() async {
        let day = DayDate(.now)
        if let loaded = try? await session.send(MealPlanEndpoints.entries(from: day, to: day.adding(days: Self.daysAhead))) {
            today = day
            entries = loaded
        }
    }
}
