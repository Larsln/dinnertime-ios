import Foundation
import Testing
@testable import DinnertimeKit

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

    @Test func amountsToBuyAreWholeGramsAndMilliliters() {
        #expect(german.wholeString(66.67, unit: .gram) == "67 g")
        #expect(german.wholeString(62.5, unit: .milliliter) == "63 ml")
        #expect(german.wholeString(0.4, unit: .gram) == "0 g")
        #expect(german.wholeString(999.4, unit: .gram) == "999 g")
    }

    @Test func amountsToBuySwitchToLargeUnitsFromARoundedThousand() {
        #expect(german.wholeString(999.6, unit: .gram) == "1 kg")
        #expect(german.wholeString(999.5, unit: .milliliter) == "1 l")
        #expect(german.wholeString(1000, unit: .gram) == "1 kg")
        #expect(german.wholeString(1234.5, unit: .gram) == "1,23 kg")
        #expect(german.wholeString(2250, unit: .milliliter) == "2,25 l")
    }

    @Test func piecesToBuyKeepTheirDecimals() {
        #expect(german.wholeString(1.5, unit: .piece) == german.string(1.5, unit: .piece))
        #expect(german.wholeString(1.5, unit: .piece).hasPrefix("1,5 "))
    }

    @Test func recipeQuantitiesKeepTheirDecimals() throws {
        let recipe = try RecipeEndpoints.detail(id: 1).decode(Fixture.data("recipe"))

        #expect(recipe.ingredients[0].text(scaledBy: 0.2225, formatter: german).amount == "66,75 g")
        #expect(german.string(66.67, unit: .gram) == "66,67 g")
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

        #expect(rated.averageRatingText(locale: Locale(identifier: "en_US")) == "3.8")
        #expect(StarScale.starsText(points: 7, locale: Locale(identifier: "de_DE")) == "3,5")
        #expect(StarScale.starsText(points: 8, locale: Locale(identifier: "de_DE")) == "4")
        #expect(rated.averageRatingText(locale: Locale(identifier: "de_DE")) == "3,8")
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

    @Test func approximateAmountsStartWithTheSignAndAreWhole() throws {
        func item(approximate: Bool, packages: String = "[]") throws -> ShoppingListItem {
            let json = #"""
            {"data": {"id": 9, "label": null, "is_manual": false, "needed_amount": 62.5, "purchase_amount": 62.5,
            "is_approximate": \#(approximate), "packages": \#(packages), "extra_amounts": [],
            "product": {"id": 2, "name": "Parmesan", "plural_name": null, "base_unit": "g", "status": "confirmed"}}}
            """#
            return try ShoppingEndpoints.setChecked(true, itemID: 9).decode(Data(json.utf8))
        }
        let packed = try item(approximate: true, packages: #"[{"package_id": 1, "label": "Lidl", "amount": 66.67, "count": 2}]"#)

        #expect(try item(approximate: true).shortPurchaseText(formatter: german) == "≈ 63 g")
        #expect(try item(approximate: true).purchaseText(formatter: german) == "≈ 63 g")
        #expect(try item(approximate: false).shortPurchaseText(formatter: german) == "63 g")
        #expect(packed.shortPurchaseText(formatter: german) == "≈ 2 × 67 g")
        #expect(packed.purchaseText(formatter: german) == "≈ 2 × Lidl 67 g")
    }

    @Test func boughtPackagesNameTheirStoreOrOnlyTheirSize() throws {
        func item(_ packages: String, unit: String = "g") throws -> ShoppingListItem {
            let json = #"""
            {"data": {"id": 9, "label": null, "is_manual": false, "needed_amount": 300, "purchase_amount": 400,
            "packages": \#(packages), "extra_amounts": [],
            "product": {"id": 2, "name": "Schmand", "plural_name": null, "base_unit": "\#(unit)", "status": "confirmed"}}}
            """#
            return try ShoppingEndpoints.setChecked(true, itemID: 9).decode(Data(json.utf8))
        }
        let mixed = try item(#"[{"package_id": 1, "label": "Lidl", "amount": 200, "count": 1}, {"package_id": 2, "label": "", "amount": 200, "count": 2}]"#)
        let pieces = try item(#"[{"package_id": 1, "label": "Lidl", "amount": 1, "count": 3}, {"package_id": 2, "label": " ", "amount": 1, "count": 2}]"#, unit: "piece")

        #expect(mixed.purchaseText(formatter: english) == "1 × Lidl 200 g + 2 × 200 g")
        #expect(pieces.purchaseText(formatter: english) == "3 × Lidl + 2 × \(english.string(1, unit: .piece))")
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
