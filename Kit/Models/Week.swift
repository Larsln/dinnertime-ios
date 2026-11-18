import Foundation

/// Seven consecutive days, the period the plan and the shopping list work with.
public struct Week: Hashable, Sendable {
    /// First day of the week.
    public let start: DayDate

    /// Last day of the week.
    public var end: DayDate {
        start.adding(days: 6)
    }

    /// All seven days in order.
    public var days: [DayDate] {
        (0..<7).map(start.adding(days:))
    }

    public init(start: DayDate) {
        self.start = start
    }

    /// The week that contains `date`, starting on the first weekday of `calendar`.
    public init(containing date: Date, calendar: Calendar = .current) {
        let weekday = calendar.component(.weekday, from: date)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        start = DayDate(date, calendar: calendar).adding(days: -offset)
    }

    /// Number of the week within its year, as `calendar` counts it.
    public func number(in calendar: Calendar = .current) -> Int {
        calendar.component(.weekOfYear, from: start.date(in: calendar))
    }

    /// The week `weeks` after this one; negative values go back.
    public func shifted(byWeeks weeks: Int) -> Week {
        Week(start: start.adding(days: weeks * 7))
    }

    /// Whether `day` lies within this week.
    public func contains(_ day: DayDate) -> Bool {
        start <= day && day <= end
    }
}
