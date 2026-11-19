import Foundation
import Testing
@testable import DinnertimeKit

/// Amount markers in the text of a step and their scaling to the servings.
struct StepTextTests {
    private let german = AmountFormatter(locale: Locale(identifier: "de_DE"))

    private func rendered(_ raw: String, scale: Double) -> String {
        StepText(raw).rendered(scaledBy: scale, formatter: german)
    }

    @Test func scalesWholeNumbers() {
        #expect(rendered("{250} g Mehl", scale: 2) == "500 g Mehl")
    }

    @Test func readsDecimalsWithCommaOrDot() {
        #expect(rendered("{1,5} EL Öl", scale: 2) == "3 EL Öl")
        #expect(rendered("{1.5} EL Öl", scale: 2) == "3 EL Öl")
    }

    @Test func readsFractions() {
        #expect(rendered("{1/2} TL Salz", scale: 3) == "1\u{202F}½ TL Salz")
    }

    @Test func scalesSeveralMarkersInOneStep() {
        #expect(rendered("{2}–{3} EL", scale: 0.5) == "1–1\u{202F}½ EL")
        #expect(rendered("{250} g Mehl mit {2} Eiern verrühren und 10 Minuten ruhen lassen.", scale: 2)
            == "500 g Mehl mit 4 Eiern verrühren und 10 Minuten ruhen lassen.")
    }

    @Test func keepsBracesThatAreNoMarkers() {
        #expect(rendered("{abc} und {}", scale: 2) == "{abc} und {}")
        #expect(rendered("{1/0}", scale: 2) == "{1/0}")
        #expect(rendered("{ 2 } und {1,} und {-1} und {1/2/3}", scale: 2) == "{ 2 } und {1,} und {-1} und {1/2/3}")
        #expect(StepText("{1/0} Prise").segments == [.text("{1/0} Prise")])
    }

    @Test func keepsStepsWithoutMarkers() {
        #expect(rendered("10 Minuten bei 180 °C", scale: 2) == "10 Minuten bei 180 °C")
        #expect(rendered("", scale: 2) == "")
    }

    @Test func splitsIntoSegments() {
        #expect(StepText("{250} g Mehl mit {1/2} TL Salz").segments
            == [.amount(250), .text(" g Mehl mit "), .amount(0.5), .text(" TL Salz")])
    }

    @Test func writesSmallAmountsWithFractions() {
        #expect(rendered("{1} TL Salz", scale: 0.5) == "½ TL Salz")
        #expect(rendered("{3} Eier", scale: 0.75) == "2\u{202F}¼ Eier")
        #expect(rendered("{1} Prise", scale: 0.1) == "0,1 Prise")
    }

    @Test func keepsAmountsFromTwentyOnDecimal() {
        #expect(rendered("{13} g Hefe", scale: 1.5) == "19\u{202F}½ g Hefe")
        #expect(rendered("{41} g Butter", scale: 0.5) == "20,5 g Butter")
        #expect(rendered("{20} g Butter", scale: 1) == "20 g Butter")
    }

    @Test func tellsAmountsFromPlainText() {
        let parts = StepText("Mit {2} Eiern").parts(scaledBy: 1.5, formatter: german)

        #expect(parts.map(\.text) == ["Mit ", "3", " Eiern"])
        #expect(parts.map(\.isAmount) == [false, true, false])
    }
}
