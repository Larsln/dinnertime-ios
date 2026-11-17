import MealplannerKit
import Observation

/// Loads the recipes that match a search text and a tag, page by page.
@MainActor
@Observable
final class RecipeListModel: ErrorReporting {
    /// The filter the list is loaded for.
    struct Query: Hashable {
        var text = ""
        var tagID: Int?
    }

    var query = Query()
    var errorMessage: String?
    private(set) var recipes: [RecipeSummary] = []
    private(set) var tags: [Tag] = []
    private(set) var hasMore = false
    private(set) var hasLoaded = false

    private var nextPage = 1
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Tags of one group, for the filter menu.
    func tags(of kind: Tag.Kind) -> [Tag] {
        tags.filter { $0.type == kind }
    }

    /// Loads the first page for the current query.
    func reload() async {
        await attempt {
            let page = try await session.send(RecipeEndpoints.list(search: query.text, tagID: query.tagID))
            recipes = page.items
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
            hasLoaded = true
        }
    }

    /// Appends the next page.
    func loadMore() async {
        await attempt {
            let page = try await session.send(RecipeEndpoints.list(search: query.text, tagID: query.tagID, page: nextPage))
            recipes += page.items
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
        }
    }

    /// Loads the tags to filter by.
    func loadTags() async {
        await attempt {
            tags = try await session.send(RecipeEndpoints.tags)
        }
    }
}
