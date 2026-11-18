import MealplannerKit
import Observation

/// Searches the products of the household by name or alias, page by page.
@MainActor
@Observable
final class ProductSearchModel: ErrorReporting {
    var searchText = ""
    var errorMessage: String?
    private(set) var products: [Product] = []
    private(set) var hasMore = false
    private(set) var hasLoaded = false

    private var nextPage = 1
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// The typed name, if it is not empty and no listed product carries it.
    var creatableName: String? {
        guard let name = searchText.nilIfBlank, hasLoaded else {
            return nil
        }
        let isKnown = products.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        return isKnown ? nil : name
    }

    /// Loads the first page of products that match the search text.
    func search() async {
        await attempt {
            let page = try await session.send(ProductEndpoints.search(searchText))
            products = page.items
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
            hasLoaded = true
        }
    }

    /// Appends the next page.
    func loadMore() async {
        await attempt {
            let page = try await session.send(ProductEndpoints.search(searchText, page: nextPage))
            let known = Set(products.map(\.id))
            products += page.items.filter { !known.contains($0.id) }
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
        }
    }

    /// Creates a product from the typed name; the server suggests its other values.
    func create() async -> Product? {
        guard let name = creatableName else {
            return nil
        }
        var created: Product?
        await attempt {
            created = try await session.send(ProductEndpoints.create(name: name))
        }
        return created
    }
}
