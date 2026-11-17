import Foundation
import MealplannerKit

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
}
