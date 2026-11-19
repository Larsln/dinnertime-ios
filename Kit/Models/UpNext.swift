import Foundation


extension Sequence where Element == MealPlanEntry {
    /// The meal to cook next: the first planned meal from `today` on that is not cooked yet,
    /// earlier days first and the meals of a day in the order they are eaten.
    public func nextMeal(from today: DayDate) -> MealPlanEntry? {
        let order = MealType.allCases
        return filter { !$0.isCooked && $0.date >= today }
            .min { first, second in
                (first.date, order.firstIndex(of: first.meal) ?? 0, first.id) < (second.date, order.firstIndex(of: second.meal) ?? 0, second.id)
            }
    }

    /// Whether anything is planned for `day`, cooked or not.
    public func isPlanned(on day: DayDate) -> Bool {
        contains { $0.date == day }
    }
}

extension DayDate {
    /// Number of days from `other` to this day; negative when this day is earlier.
    public func days(since other: DayDate) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar.dateComponents([.day], from: other.date(in: calendar), to: date(in: calendar)).day ?? 0
    }
}
