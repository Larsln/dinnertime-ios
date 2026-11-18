import Foundation

/// The matrix of days and meals in which the user chooses the slots to plan.
///
/// Slots that already have a plan entry are not open and can never be selected. Presets
/// replace the selection with the open slots of a set of days and a set of meals.
public struct MealSlotSelection: Sendable {
    /// Quick choices of days.
    public enum DayPreset: CaseIterable, Sendable {
        case allDays, weekdays, weekend
    }

    /// Quick choices of meals; `allMeals` covers the visible columns.
    public enum MealPreset: CaseIterable, Sendable {
        case dinner, lunch, allMeals
    }

    /// Meals shown before the user asks for more.
    public static let defaultMeals: [MealType] = [.breakfast, .lunch, .dinner]

    /// Rows of the matrix.
    public let days: [DayDate]
    /// Whether dessert and snack have columns as well; hiding them takes their slots out of the selection.
    public var showsAllMeals = false {
        didSet {
            selected = selected.filter { meals.contains($0.meal) }
        }
    }
    /// Day preset the selection was last set with.
    public private(set) var dayPreset = DayPreset.allDays
    /// Meal preset the selection was last set with.
    public private(set) var mealPreset = MealPreset.dinner
    public private(set) var selected: Set<MealSlot> = []

    private let planned: Set<MealSlot>
    private let calendar: Calendar

    /// Creates the matrix for `days` with nothing selected; `planned` lists the slots that have an entry.
    public init(days: [DayDate], planned: Set<MealSlot>, calendar: Calendar = .current) {
        self.days = days
        self.planned = planned
        self.calendar = calendar
    }

    /// Columns of the matrix.
    public var meals: [MealType] {
        showsAllMeals ? MealType.allCases : Self.defaultMeals
    }

    /// The selected slots by day and, within a day, in the order of the meals.
    public var slots: [MealSlot] {
        days.flatMap { day in
            MealType.allCases.map { MealSlot(date: day, meal: $0) }.filter(selected.contains)
        }
    }

    /// Whether the selection is exactly what the two presets stand for.
    public var matchesPresets: Bool {
        selected == presetSlots
    }

    /// Whether a slot has no entry yet and can be selected.
    public func isOpen(_ slot: MealSlot) -> Bool {
        !planned.contains(slot)
    }

    /// Selects an open slot or takes it out of the selection.
    public mutating func toggle(_ slot: MealSlot) {
        guard isOpen(slot) else {
            return
        }
        if selected.remove(slot) == nil {
            selected.insert(slot)
        }
    }

    /// Replaces the selection with the open slots of `preset` and the current meal preset.
    public mutating func apply(_ preset: DayPreset) {
        dayPreset = preset
        selected = presetSlots
    }

    /// Replaces the selection with the open slots of the current day preset and `preset`.
    public mutating func apply(_ preset: MealPreset) {
        mealPreset = preset
        selected = presetSlots
    }

    private var presetSlots: Set<MealSlot> {
        let slots = presetDays.flatMap { day in presetMeals.map { MealSlot(date: day, meal: $0) } }
        return Set(slots.filter(isOpen))
    }

    private var presetDays: [DayDate] {
        switch dayPreset {
        case .allDays: days
        case .weekdays: days.filter { !isWeekend($0) }
        case .weekend: days.filter(isWeekend)
        }
    }

    private var presetMeals: [MealType] {
        switch mealPreset {
        case .dinner: [.dinner]
        case .lunch: [.lunch]
        case .allMeals: meals
        }
    }

    private func isWeekend(_ day: DayDate) -> Bool {
        calendar.isDateInWeekend(day.date(in: calendar))
    }
}
