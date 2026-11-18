import Foundation
import Testing
@testable import MealplannerKit

/// The manifest of the product icons and the choice of the icon to show.
struct ProductIconCatalogTests {
    private let manifest = Data(#"""
    [
        {"key": "milk", "de": "Milch", "en": "Milk", "section": "chilled", "source": "tabler"},
        {"key": "apple", "de": "Apfel", "en": "Apple", "section": "produce", "source": "tabler"},
        {"key": "cheese", "de": "Käse", "en": "Cheese", "section": "chilled", "source": "own"},
        {"key": "section-chilled", "de": "Kühlregal", "en": "Chilled", "section": "chilled", "source": "own"},
        {"key": "section-other", "de": "Sonstiges", "en": "Other", "section": "other", "source": "tabler"}
    ]
    """#.utf8)

    private func catalog() throws -> ProductIconCatalog {
        try ProductIconCatalog(manifest: manifest)
    }

    @Test func readsTheManifest() throws {
        let entries = try catalog().entries

        #expect(entries.count == 5)
        #expect(entries[0] == ProductIconCatalog.Entry(key: "milk", de: "Milch", en: "Milk", section: "chilled"))
        #expect(entries.map(\.isSectionIcon) == [false, false, false, true, true])
    }

    @Test func rejectsWhatIsNoManifest() {
        #expect(throws: (any Error).self) {
            try ProductIconCatalog(manifest: Data(#"{"key": "milk"}"#.utf8))
        }
    }

    @Test func offersProductIconsSortedByLocalizedName() throws {
        #expect(try catalog().productIcons(matching: "", languageCode: "de").map(\.key) == ["apple", "cheese", "milk"])
        #expect(try catalog().productIcons(matching: "  ", languageCode: "en").map(\.key) == ["apple", "cheese", "milk"])
    }

    @Test func filtersByTheNameInTheLanguageOfTheApp() throws {
        let catalog = try catalog()

        #expect(catalog.productIcons(matching: "kase", languageCode: "de").map(\.key) == ["cheese"])
        #expect(catalog.productIcons(matching: "KÄS", languageCode: "de").map(\.key) == ["cheese"])
        #expect(catalog.productIcons(matching: "chee", languageCode: "de").isEmpty)
        #expect(catalog.productIcons(matching: "chee", languageCode: "en").map(\.key) == ["cheese"])
        #expect(catalog.productIcons(matching: "l", languageCode: "fr").map(\.key) == ["apple", "milk"])
    }

    @Test func sectionIconsAreNeverOffered() throws {
        #expect(try catalog().productIcons(matching: "Kühl", languageCode: "de").isEmpty)
    }

    @Test func ownIconComesBeforeTheSectionAndTheGeneralOne() {
        #expect(ProductIconCatalog.candidates(icon: "milk", sectionKey: "chilled") == ["milk", "section-chilled", "section-other"])
        #expect(ProductIconCatalog.candidates(icon: nil, sectionKey: "meat_fish") == ["section-meat-fish", "section-other"])
        #expect(ProductIconCatalog.candidates(icon: nil, sectionKey: "pasta_rice_cereal") == ["section-pasta-rice-cereal", "section-other"])
        #expect(ProductIconCatalog.candidates(icon: nil, sectionKey: nil) == ["section-other"])
    }

    @Test func everySectionOfTheShippedManifestHasItsFallback() throws {
        let url = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "App/Resources/ProductIcons.json")
        let shipped = try ProductIconCatalog(manifest: Data(contentsOf: url))
        let keys = Set(shipped.entries.map(\.key))
        let fallbacks = Set(shipped.entries.flatMap { ProductIconCatalog.candidates(icon: nil, sectionKey: $0.section) })

        #expect(keys.count == shipped.entries.count)
        #expect(fallbacks.isSubset(of: keys))
        #expect(shipped.productIcons(matching: "", languageCode: "de").count == shipped.entries.count - fallbacks.count)
    }
}
