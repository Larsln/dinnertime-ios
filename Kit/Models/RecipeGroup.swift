import Foundation

/// A named group of ingredient lines or steps while a recipe is edited, such as "Base" or "Filling".
///
/// The API stores the name as the `section` of every row; a group without a title holds
/// the rows that belong to no component.
public struct RecipeGroup<Row>: Identifiable {
    public let id = UUID()
    public var title: String
    public var rows: [Row]

    public init(title: String = "", rows: [Row]) {
        self.title = title
        self.rows = rows
    }

    /// The title as the API stores it: trimmed, or `nil` when nothing is left.
    public var section: String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Turns stored items into groups: consecutive items with the same section form one group.
    public static func grouping<Item>(_ items: [Item], by section: (Item) -> String?, row: (Item) -> Row) -> [RecipeGroup] {
        var groups: [RecipeGroup] = []
        for item in items {
            let title = section(item) ?? ""
            if let last = groups.indices.last, groups[last].title == title {
                groups[last].rows.append(row(item))
            } else {
                groups.append(RecipeGroup(title: title, rows: [row(item)]))
            }
        }
        return groups
    }
}

extension Array {
    /// Turns groups back into lines that each carry the section of their group; rows for which `line` answers `nil` are dropped.
    public func flattened<Row, Line>(_ line: (Row, String?) -> Line?) -> [Line] where Element == RecipeGroup<Row> {
        flatMap { group in
            group.rows.compactMap { line($0, group.section) }
        }
    }
}
