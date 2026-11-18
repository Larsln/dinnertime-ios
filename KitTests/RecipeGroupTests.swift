import Testing
@testable import MealplannerKit

/// Grouping of stored rows by section and the way back.
struct RecipeGroupTests {
    private struct Line: Equatable {
        let section: String?
        let text: String
    }

    private let stored = [
        Line(section: "Boden", text: "Mehl"),
        Line(section: "Boden", text: "Butter"),
        Line(section: nil, text: "Salz"),
        Line(section: "Füllung", text: "Quark"),
        Line(section: "Boden", text: "Zucker"),
    ]

    private func groups(_ lines: [Line]) -> [RecipeGroup<String>] {
        RecipeGroup.grouping(lines, by: \.section, row: \.text)
    }

    private func lines(_ groups: [RecipeGroup<String>]) -> [Line] {
        groups.flattened { text, section in
            text.isEmpty ? nil : Line(section: section, text: text)
        }
    }

    @Test func consecutiveRowsWithTheSameSectionFormOneGroup() {
        let groups = groups(stored)

        #expect(groups.map(\.title) == ["Boden", "", "Füllung", "Boden"])
        #expect(groups.map(\.rows) == [["Mehl", "Butter"], ["Salz"], ["Quark"], ["Zucker"]])
        #expect(Set(groups.map(\.id)).count == 4)
    }

    @Test func nothingStoredGivesNoGroups() {
        #expect(groups([]).isEmpty)
    }

    @Test func flatteningRestoresTheStoredLines() {
        #expect(lines(groups(stored)) == stored)
    }

    @Test func everyRowCarriesTheTrimmedTitleOfItsGroup() {
        let groups = [RecipeGroup(title: "  Deko ", rows: ["Puderzucker", "Beeren"]), RecipeGroup(title: "   ", rows: ["Minze"])]

        #expect(lines(groups) == [
            Line(section: "Deko", text: "Puderzucker"),
            Line(section: "Deko", text: "Beeren"),
            Line(section: nil, text: "Minze"),
        ])
    }

    @Test func emptyRowsAreDropped() {
        let groups = [RecipeGroup(title: "Boden", rows: ["", "Mehl", ""]), RecipeGroup(title: "Leer", rows: [""])]

        #expect(lines(groups) == [Line(section: "Boden", text: "Mehl")])
    }
}
