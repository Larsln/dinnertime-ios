/// Telling the meals of a plan from the sides served with them.
extension Collection where Element == MealPlanEntry {
    /// The entries that stand for themselves: meals, and sides whose meal is not among the entries.
    public var meals: [MealPlanEntry] {
        let ids = Set(map(\.id))
        return filter { entry in entry.parentID.map { !ids.contains($0) } ?? true }
    }

    /// The sides served with a meal, in the order they were added; those created offline come last.
    public func sides(of meal: MealPlanEntry) -> [MealPlanEntry] {
        filter { $0.parentID == meal.id }.sorted { ($0.id < 0 ? 1 : 0, abs($0.id)) < ($1.id < 0 ? 1 : 0, abs($1.id)) }
    }
}
