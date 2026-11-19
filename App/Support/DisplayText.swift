import Foundation
import DinnertimeKit

extension MealType {
    /// Name of the meal in the language of the device.
    var label: String {
        switch self {
        case .breakfast: String(localized: "Breakfast")
        case .lunch: String(localized: "Lunch")
        case .dinner: String(localized: "Dinner")
        case .dessert: String(localized: "Dessert")
        case .snack: String(localized: "Snack")
        }
    }
}

extension BaseUnit {
    /// Name of the unit next to input fields and in descriptions.
    var label: String {
        switch self {
        case .gram: "g"
        case .milliliter: "ml"
        case .piece: String(localized: "pieces")
        }
    }
}

extension BaseUnit {
    /// Full name of the unit, for choosing it and for headings.
    var name: String {
        switch self {
        case .gram: String(localized: "Grams")
        case .milliliter: String(localized: "Milliliters")
        case .piece: String(localized: "Pieces")
        }
    }
}

extension Duration {
    /// A number of minutes in hours and minutes, such as "1 hr, 5 min".
    static func text(minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

extension RecipeSummary {
    /// Preparation and cooking time together; `nil` when the recipe states neither.
    var totalTimeText: String? {
        guard prepMinutes != nil || cookMinutes != nil else {
            return nil
        }
        return Duration.text(minutes: (prepMinutes ?? 0) + (cookMinutes ?? 0))
    }
}

extension DayDate {
    /// Weekday and date, such as "Wednesday, 18 November".
    var longText: String {
        date().formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    /// Short date, such as "18 Nov 2026".
    var shortText: String {
        date().formatted(.dateTime.day().month(.abbreviated).year())
    }

    /// The days from this one until `end`, such as "16 – 22 Nov".
    func rangeText(until end: DayDate) -> String {
        (date()..<end.date()).formatted(.interval.day().month(.abbreviated))
    }

    /// Abbreviated weekday and day of the month, such as "Wed 18".
    var weekdayDayText: String {
        date().formatted(.dateTime.weekday(.abbreviated).day())
    }

    /// Initial of the weekday, such as "W".
    var weekdayInitial: String {
        date().formatted(.dateTime.weekday(.narrow))
    }

    /// Day of the month, such as "18".
    var dayNumberText: String {
        date().formatted(.dateTime.day())
    }

    /// Abbreviated weekday, such as "Wed".
    var weekdayText: String {
        date().formatted(.dateTime.weekday(.abbreviated))
    }
}

extension Week {
    /// First and last day, such as "16 – 22 Nov".
    var rangeText: String {
        start.rangeText(until: end)
    }

    /// Calendar week and range, such as "Week 47 · 16 – 22 Nov".
    var titleText: String {
        "\(String(localized: "Week \(number())")) · \(rangeText)"
    }

    /// Whether today lies within the week.
    var isCurrent: Bool {
        contains(DayDate(.now))
    }
}
