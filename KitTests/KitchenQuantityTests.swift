import Foundation
import Testing
@testable import DinnertimeKit

/// Quantities written with kitchen fractions and read back from what a cook types.
struct KitchenQuantityTests {
    private let german = AmountFormatter(locale: Locale(identifier: "de_DE"))
    private let english = AmountFormatter(locale: Locale(identifier: "en_US"))

    private func unit(kind: String) throws -> MeasureUnit? {
        let json = #"{"id": 1, "key": null, "code": "x", "name": "x", "plural_name": null, "kind": "\#(kind)", "factor_to_base": null}"#
        return try JSONCoding.makeDecoder().decode(MeasureUnit.self, from: Data(json.utf8))
    }

    @Test(arguments: [
        (0.5, "½"), (1.5, "1\u{202F}½"), (0.33, "⅓"), (0.667, "⅔"), (2.25, "2\u{202F}¼"), (0.125, "⅛"),
        (0.1, "0,1"), (3, "3"), (0.99, "1"), (2.9, "2,9"),
        (0.75, "¾"), (0.375, "⅜"), (0.625, "⅝"), (0.875, "⅞"), (0, "0"), (12.5, "12\u{202F}½"),
    ])
    func writesKitchenStyle(value: Double, text: String) {
        #expect(KitchenQuantity.format(value, formatter: german) == text)
    }

    @Test func metricStyleNeverUsesFractions() {
        #expect(KitchenQuantity.format(1.5, style: .metric, formatter: german) == "1,5")
        #expect(KitchenQuantity.format(0.5, style: .metric, formatter: english) == "0.5")
        #expect(KitchenQuantity.format(250, style: .metric, formatter: german) == "250")
    }

    @Test func toleranceIsStrict() {
        #expect(KitchenQuantity.format(0.52, formatter: german) == "0,52")
        #expect(KitchenQuantity.format(0.519, formatter: german) == "½")
        #expect(KitchenQuantity.format(0.481, formatter: german) == "½")
        #expect(KitchenQuantity.format(0.47, formatter: german) == "0,47")
        #expect(KitchenQuantity.format(1.019, formatter: german) == "1")
        #expect(KitchenQuantity.format(1.03, formatter: german) == "1,03")
    }

    @Test func negativeValuesStayDecimal() {
        #expect(KitchenQuantity.format(-0.5, formatter: german) == "-0,5")
    }

    @Test func otherDecimalsKeepTwoFractionDigits() {
        #expect(KitchenQuantity.format(0.4567, formatter: german) == "0,46")
        #expect(KitchenQuantity.format(2.9, formatter: english) == "2.9")
    }

    @Test func editableTextReadsBackAsTheSameNumber() {
        #expect(KitchenQuantity.editable(1.5, formatter: german) == "1\u{202F}½")
        #expect(KitchenQuantity.editable(1.5, style: .metric, formatter: german) == "1,5")
        #expect(KitchenQuantity.editable(0.045, formatter: german) == "0,045")
        #expect(KitchenQuantity.editable(1234.5, formatter: german) == "1234,5")
        #expect(KitchenQuantity.editable(1000.5, formatter: english) == "1000.5")
        #expect(KitchenQuantity.parse(KitchenQuantity.editable(2.25, formatter: german)) == 2.25)
        #expect(KitchenQuantity.parse(KitchenQuantity.editable(0.045, formatter: german)) == 0.045)
    }

    @Test func unitsOfMassAndVolumeAreMetric() throws {
        #expect(try unit(kind: "mass").quantityStyle == .metric)
        #expect(try unit(kind: "volume").quantityStyle == .metric)
        #expect(try unit(kind: "product_specific").quantityStyle == .kitchen)
        #expect(MeasureUnit?.none.quantityStyle == .kitchen)
    }

    @Test(arguments: [
        ("1/2", 0.5), ("1 1/2", 1.5), ("¾", 0.75), ("2¼", 2.25), ("1,5", 1.5),
        ("½", 0.5), ("1½", 1.5), ("1 ½", 1.5), ("1\u{202F}½", 1.5), ("1\u{00A0}1/2", 1.5), ("1   1/2", 1.5),
        ("0.25", 0.25), ("3", 3), ("  2  ", 2), (" 1/4\n", 0.25), ("10/4", 2.5), ("0", 0),
    ])
    func readsQuantities(text: String, value: Double) {
        #expect(KitchenQuantity.parse(text) == value)
    }

    @Test(arguments: ["abc", "1/0", "-1", "", "1/2/3", ".5", "5.", "1,", "1 1/0", "½½", "½1", "1 2", "1.5 ½", "1,5/2", "1e3", "٣", "   "])
    func rejectsUnreadableInput(text: String) {
        #expect(KitchenQuantity.parse(text) == nil)
    }

    @Test func readsThirdsExactly() {
        #expect(KitchenQuantity.parse("⅓") == 1.0 / 3)
        #expect(KitchenQuantity.parse("2/3") == 2.0 / 3)
    }

    @Test func ingredientQuantitiesFollowTheirUnit() throws {
        let recipe = try RecipeEndpoints.detail(id: 1).decode(Fixture.data("recipe"))

        #expect(recipe.ingredients[0].text(scaledBy: 0.005, formatter: german).amount == "1,5 g")
        #expect(recipe.ingredients[1].text(scaledBy: 0.5, formatter: german) == IngredientText(amount: "1\u{202F}½", name: "Zwiebeln"))
        #expect(recipe.ingredients[1].text(scaledBy: 0.25, formatter: german) == IngredientText(amount: "¾", name: "Zwiebel"))
    }
}
