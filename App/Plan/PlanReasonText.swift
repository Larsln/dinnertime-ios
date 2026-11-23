import DinnertimeKit
import Foundation

extension PlanReason {
    /// The reason in words, such as "Shares cream with Soup (Thu)"; `nil` for reasons this app does not know.
    var text: String? {
        switch self {
        case let .shares(products, partners):
            let meals = partners.map { "\($0.title) (\($0.date.weekdayText))" }
            return String(localized: "Shares \(Self.list(products)) with \(Self.list(meals))")
        case let .pantry(products):
            return String(localized: "Uses \(Self.list(products)) from the pantry")
        case .favorite:
            return String(localized: "Your favorite")
        case let .rating(value):
            return String(localized: "Well rated, \((value / 2).formatted(.number.precision(.fractionLength(0...1)))) stars")
        case let .lastPlanned(days):
            return String(localized: "Last planned \(days) days ago")
        case .notRecent:
            return String(localized: "Not planned for a while")
        case let .quick(minutes):
            return minutes.map { String(localized: "Quick to make, \($0) min") } ?? String(localized: "Quick to make")
        case .unknown:
            return nil
        }
    }

    /// The symbol in front of the reason.
    var systemImage: String {
        switch self {
        case .shares:
            "link"
        case .pantry:
            "archivebox"
        case .favorite:
            "heart"
        case .rating:
            "star"
        case .lastPlanned, .notRecent:
            "clock.arrow.circlepath"
        case .quick:
            "bolt"
        case .unknown:
            "questionmark"
        }
    }

    /// Whether the reason ties the meal to the rest of the plan or the pantry, which is what planning is about.
    var isAboutTheWeek: Bool {
        switch self {
        case .shares, .pantry:
            true
        default:
            false
        }
    }

    private static func list(_ names: [String]) -> String {
        ListFormatter.localizedString(byJoining: names)
    }
}
