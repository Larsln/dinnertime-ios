import Foundation
import Testing
@testable import MealplannerKit

/// Display of amounts and ingredient lines.
struct FormattingTests {
    private let english = AmountFormatter(locale: Locale(identifier: "en_US"))
    private let german = AmountFormatter(locale: Locale(identifier: "de_DE"))

    @Test func keepsSmallAmountsInBaseUnit() {
        #expect(english.string(250, unit: .gram) == "250 g")
        #expect(english.string(999, unit: .milliliter) == "999 ml")
        #expect(english.string(12.5, unit: .gram) == "12.5 g")
    }

    @Test func switchesToLargeUnits() {
        #expect(english.string(1500, unit: .gram) == "1.5 kg")
        #expect(english.string(1000, unit: .milliliter) == "1 l")
        #expect(german.string(2250, unit: .gram) == "2,25 kg")
    }

    @Test func roundsToTwoFractionDigits() {
        #expect(english.number(0.333333) == "0.33")
        #expect(english.number(3) == "3")
        #expect(english.number(12000) == "12000")
    }

    @Test func piecesStartWithTheNumber() {
        #expect(english.string(3, unit: .piece).hasPrefix("3 "))
    }

    @Test func scalesIngredients() throws {
        let recipe = try RecipeEndpoints.detail(id: 1).decode(Fixture.data("recipe"))

        #expect(recipe.ingredients[0].text(scaledBy: 1.5, formatter: english) == IngredientText(amount: "450 g", name: "Schmand"))
        #expect(recipe.ingredients[1].text(scaledBy: 1, formatter: english) == IngredientText(amount: "3", name: "Zwiebeln"))
        #expect(recipe.ingredients[1].text(scaledBy: 1.0 / 3, formatter: english) == IngredientText(amount: "1", name: "Zwiebel"))
        #expect(recipe.ingredients[2].text(scaledBy: 2, formatter: english) == IngredientText(amount: nil, name: "Salz und Pfeffer"))
    }

    @Test func averageRatingKeepsOneDecimal() throws {
        let rated = try RecipeEndpoints.detail(id: 1).decode(Fixture.data("recipe")).summary
        let unrated = try RecipeEndpoints.list().decode(Fixture.data("recipes-page")).items[0]

        #expect(rated.averageRatingText(locale: Locale(identifier: "en_US")) == "7.5")
        #expect(rated.averageRatingText(locale: Locale(identifier: "de_DE")) == "7,5")
        #expect(unrated.averageRatingText() == nil)
    }

    @Test func labelLineStartsWithTheCourse() throws {
        let recipe = try RecipeEndpoints.list().decode(Fixture.data("recipes-page")).items[0]

        #expect(recipe.labelLine == "Hauptgericht · Abendessen · Vegetarisch")
    }

    @Test func purchaseTextOfNeedsThatCannotBeConverted() throws {
        let json = #"""
        {"data": {"id": 9, "label": null, "is_manual": false, "needed_amount": null, "purchase_amount": null,
        "packages": [], "extra_amounts": [{"quantity": 2, "unit_code": "Stück"}, {"quantity": 0.5, "unit_code": "Bund"}],
        "product": {"id": 2, "name": "Apfel", "plural_name": null, "base_unit": "g", "status": "confirmed"}}}
        """#
        let item = try ShoppingEndpoints.setChecked(true, itemID: 9).decode(Data(json.utf8))

        #expect(item.purchaseText(formatter: english) == "2 Stück + 0.5 Bund")
    }

    @Test func weekStartsOnTheFirstWeekdayOfTheCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Berlin"))
        calendar.firstWeekday = 2
        let wednesday = DayDate(year: 2026, month: 11, day: 18).date(in: calendar)
        let week = Week(containing: wednesday, calendar: calendar)

        #expect(week.start == DayDate(year: 2026, month: 11, day: 16))
        #expect(week.end == DayDate(year: 2026, month: 11, day: 22))
        #expect(week.days.count == 7)
        #expect(week.number(in: calendar) == 47)
        #expect(week.shifted(byWeeks: -1).start == DayDate(year: 2026, month: 11, day: 9))
        #expect(week.contains(DayDate(year: 2026, month: 11, day: 22)))
        #expect(!week.contains(DayDate(year: 2026, month: 11, day: 23)))
    }

    @Test func findsLinksInSharedText() {
        let text = "Schau dir das an! https://vm.tiktok.com/ZGabc123/ #rezept"

        #expect(LinkExtractor.firstURL(in: text)?.absoluteString == "https://vm.tiktok.com/ZGabc123/")
        #expect(LinkExtractor.firstURL(in: "kein Link, nur mail@example.org") == nil)
    }
}
