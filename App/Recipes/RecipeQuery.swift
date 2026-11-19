import Foundation

extension RecipeListModel {
    /// What the list is loaded for: a search text and the filters, of which each group narrows the list.
    struct Query: Hashable {
        var text = ""
        /// Keys of the courses a recipe has to be one of.
        var courses: [String] = []
        /// Ids of the meal tags, of which a recipe has to suit one, and of the other tags, which it has to carry all.
        var tagIDs: [Int] = []
        var favoritesOnly = false

        /// Number of filters that are switched on; the search text is none of them.
        var filterCount: Int {
            courses.count + tagIDs.count + (favoritesOnly ? 1 : 0)
        }

        /// Whether anything but the search text narrows the list.
        var isFiltered: Bool {
            filterCount > 0
        }

        /// Whether a search text or a filter narrows the list.
        var isNarrowed: Bool {
            isFiltered || !text.trimmingCharacters(in: .whitespaces).isEmpty
        }

        /// Switches a course on, or off if it is on.
        mutating func toggle(course key: String) {
            courses = courses.contains(key) ? courses.filter { $0 != key } : courses + [key]
        }

        /// Switches a tag on, or off if it is on.
        mutating func toggle(tagID: Int) {
            tagIDs = tagIDs.contains(tagID) ? tagIDs.filter { $0 != tagID } : tagIDs + [tagID]
        }

        /// Switches every filter off and keeps the search text.
        mutating func resetFilters() {
            self = Query(text: text)
        }
    }

    /// A filter that is switched on, as the chips above the list name it.
    struct ActiveFilter: Identifiable, Hashable {
        /// What the filter restricts the list to.
        enum Kind: Hashable {
            case course(String)
            case tag(Int)
            case favorites
        }

        let kind: Kind
        /// Name of the course or the tag; `nil` for the favorites, whose name the app translates.
        let name: String?

        var id: Kind {
            kind
        }
    }

    /// The filters that are switched on: courses, tags and the favorites, each in the order the filter sheet lists them.
    var activeFilters: [ActiveFilter] {
        let chosenCourses = courses.filter { query.courses.contains($0.key) }.map { ActiveFilter(kind: .course($0.key), name: $0.name) }
        let chosenTags = (tags(of: .meal) + tags(of: .tag)).filter { query.tagIDs.contains($0.id) }.map { ActiveFilter(kind: .tag($0.id), name: $0.name) }
        return chosenCourses + chosenTags + (query.favoritesOnly ? [ActiveFilter(kind: .favorites, name: nil)] : [])
    }

    /// Switches one filter off.
    func remove(_ filter: ActiveFilter) {
        switch filter.kind {
        case let .course(key):
            query.courses.removeAll { $0 == key }
        case let .tag(id):
            query.tagIDs.removeAll { $0 == id }
        case .favorites:
            query.favoritesOnly = false
        }
    }
}
