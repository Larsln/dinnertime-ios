import Foundation
import Testing
@testable import MealplannerKit

/// Selection of the slots to plan in the matrix of days and meals.
struct MealSlotSelectionTests {
    private let week = Week(start: DayDate(year: 2026, month: 11, day: 16))
    private let saturday = DayDate(year: 2026, month: 11, day: 21)
    private let sunday = DayDate(year: 2026, month: 11, day: 22)

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .gmt
        return calendar
    }

    private func selection(planned: Set<MealSlot> = []) -> MealSlotSelection {
        MealSlotSelection(days: week.days, planned: planned, calendar: calendar)
    }

    @Test func startsEmptyWithThreeMeals() {
        let selection = selection()

        #expect(selection.slots.isEmpty)
        #expect(selection.meals == [.breakfast, .lunch, .dinner])
        #expect(!selection.matchesPresets)
    }

    @Test func showsAllMealsOnRequest() {
        var selection = selection()
        selection.showsAllMeals = true

        #expect(selection.meals == MealType.allCases)
    }

    @Test func togglesOpenSlots() {
        var selection = selection()
        let slot = MealSlot(date: week.start, meal: .lunch)

        selection.toggle(slot)
        #expect(selection.slots == [slot])
        selection.toggle(slot)
        #expect(selection.slots.isEmpty)
    }

    @Test func plannedSlotsCannotBeSelected() {
        let planned = MealSlot(date: week.start, meal: .dinner)
        var selection = selection(planned: [planned])

        selection.toggle(planned)
        selection.apply(.allDays)

        #expect(!selection.isOpen(planned))
        #expect(!selection.selected.contains(planned))
        #expect(selection.slots.count == 6)
        #expect(selection.matchesPresets)
    }

    @Test func dayPresetsIntersectWithTheMealPreset() {
        var selection = selection()

        selection.apply(.lunch)
        selection.apply(.weekend)
        #expect(selection.slots == [MealSlot(date: saturday, meal: .lunch), MealSlot(date: sunday, meal: .lunch)])

        selection.apply(.weekdays)
        #expect(selection.slots.map(\.date) == Array(week.days.prefix(5)))
        #expect(selection.slots.allSatisfy { $0.meal == .lunch })
    }

    @Test func allMealsCoversTheVisibleColumns() {
        var selection = selection()

        selection.apply(.allMeals)
        #expect(selection.slots.count == 21)

        selection.showsAllMeals = true
        #expect(!selection.matchesPresets)
        selection.apply(.allMeals)
        #expect(selection.slots.count == 35)
    }

    @Test func hidingMealsDeselectsTheirSlots() {
        var selection = selection()
        let dinner = MealSlot(date: week.start, meal: .dinner)

        selection.showsAllMeals = true
        selection.toggle(dinner)
        selection.toggle(MealSlot(date: week.start, meal: .snack))
        selection.toggle(MealSlot(date: sunday, meal: .dessert))
        selection.showsAllMeals = false

        #expect(selection.meals == MealSlotSelection.defaultMeals)
        #expect(selection.slots == [dinner])
    }

    @Test func slotsAreOrderedByDayAndMeal() {
        var selection = selection()

        selection.toggle(MealSlot(date: sunday, meal: .breakfast))
        selection.toggle(MealSlot(date: week.start, meal: .dinner))
        selection.toggle(MealSlot(date: week.start, meal: .lunch))

        #expect(selection.slots == [
            MealSlot(date: week.start, meal: .lunch),
            MealSlot(date: week.start, meal: .dinner),
            MealSlot(date: sunday, meal: .breakfast),
        ])
    }

    @Test func manualChangesLeaveThePresets() {
        var selection = selection()

        selection.apply(.dinner)
        #expect(selection.matchesPresets)
        selection.toggle(MealSlot(date: week.start, meal: .dinner))
        #expect(!selection.matchesPresets)
    }
}
