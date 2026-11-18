/// One meal of one day, the unit recipes are planned in.
public struct MealSlot: Encodable, Hashable, Sendable {
    public let date: DayDate
    public let meal: MealType

    public init(date: DayDate, meal: MealType) {
        self.date = date
        self.meal = meal
    }
}
