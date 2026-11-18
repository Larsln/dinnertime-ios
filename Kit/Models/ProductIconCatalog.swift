import Foundation

/// The line icons that picture products on the shopping list, as the manifest of the icon set lists them.
public struct ProductIconCatalog: Sendable {
    /// One icon of the set.
    public struct Entry: Decodable, Equatable, Identifiable, Sendable {
        /// Name of the icon, which products refer to.
        public let key: String
        /// German name.
        public let de: String
        /// English name.
        public let en: String
        /// Key of the store section the pictured product belongs to.
        public let section: String

        public var id: String {
            key
        }

        /// Whether the icon is the generic one of a store section instead of a product.
        public var isSectionIcon: Bool {
            key.hasPrefix(ProductIconCatalog.sectionPrefix)
        }

        /// The name in German or, for every other language, in English.
        public func name(languageCode: String) -> String {
            languageCode == "de" ? de : en
        }
    }

    /// Key of the icon that stands for products of no known store section.
    public static let fallbackKey = "section-other"

    fileprivate static let sectionPrefix = "section-"

    /// All icons in the order of the manifest.
    public let entries: [Entry]

    /// Reads the manifest, a JSON array of entries.
    public init(manifest: Data) throws {
        entries = try JSONDecoder().decode([Entry].self, from: manifest)
    }

    /// The icons to try for a product, most specific first: its own, that of its store section, the general one.
    ///
    /// A store section key such as `meat_fish` names the icon `section-meat-fish`.
    public static func candidates(icon: String?, sectionKey: String?) -> [String] {
        let section = sectionKey.map { sectionPrefix + $0.replacingOccurrences(of: "_", with: "-") }
        return [icon, section, fallbackKey].compactMap { $0 }
    }

    /// The icons of products whose name in the given language contains `query`, sorted by that name.
    ///
    /// Case and accents are ignored; an empty query matches every product icon. Section icons are never offered.
    public func productIcons(matching query: String, languageCode: String) -> [Entry] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return entries
            .filter { !$0.isSectionIcon }
            .filter { query.isEmpty || $0.name(languageCode: languageCode).range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
            .sorted { $0.name(languageCode: languageCode).localizedStandardCompare($1.name(languageCode: languageCode)) == .orderedAscending }
    }
}
