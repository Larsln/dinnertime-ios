import DinnertimeKit
import Observation

/// Loads the recipes that match a search text and the chosen filters, page by page.
@MainActor
@Observable
final class RecipeListModel: ErrorReporting {
    var query = Query()
    var errorMessage: String?
    private(set) var recipes: [RecipeSummary] = []
    private(set) var tags: [Tag] = []
    private(set) var courses: [Course] = []
    private(set) var hasMore = false
    private(set) var hasLoaded = false

    private var nextPage = 1
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Tags of one group, for the filter sheet.
    func tags(of kind: Tag.Kind) -> [Tag] {
        tags.filter { $0.type == kind }
    }

    /// Loads the first page for the current query.
    func reload() async {
        await attempt {
            let page = try await session.send(endpoint(page: 1))
            recipes = page.items
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
            hasLoaded = true
        }
    }

    /// Appends the next page.
    func loadMore() async {
        await attempt {
            let page = try await session.send(endpoint(page: nextPage))
            recipes += page.items
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
        }
    }

    /// Loads the courses and tags to filter by.
    func loadFilters() async {
        await attempt {
            courses = try await session.send(ReferenceEndpoints.courses)
            tags = try await session.send(ReferenceEndpoints.tags)
        }
    }

    /// The recipe an import produced; `nil` if it has none or cannot be loaded.
    func recipe(ofImport importID: Int) async -> RecipeSummary? {
        try? await session.send(ImportEndpoints.detail(id: importID)).recipe
    }

    /// Shows the changed state of a recipe that is on the list.
    func replace(_ recipe: RecipeSummary) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        }
    }

    /// Takes a deleted recipe off the list.
    func remove(id: Int) {
        recipes.removeAll { $0.id == id }
    }

    private func endpoint(page: Int) -> Endpoint<Page<RecipeSummary>> {
        RecipeEndpoints.list(search: query.text, tagIDs: query.tagIDs, courses: query.courses, favoritesOnly: query.favoritesOnly, page: page)
    }
}
