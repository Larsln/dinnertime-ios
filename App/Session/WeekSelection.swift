import Foundation
import MealplannerKit
import Observation

/// The week shown in the plan, which the shopping list is created for.
@MainActor
@Observable
final class WeekSelection {
    var week = Week(containing: .now)
}
