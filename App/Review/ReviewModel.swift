import DinnertimeKit
import Observation

/// Loads the products with suggested values and confirms them.
@MainActor
@Observable
final class ReviewModel: ErrorReporting {
    var errorMessage: String?
    private(set) var products: [Product] = []
    /// Number of products awaiting confirmation across all pages.
    private(set) var total = 0
    private(set) var hasMore = false
    private(set) var hasLoaded = false
    private(set) var confirmingIDs: Set<Int> = []

    private var nextPage = 1
    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Loads the first page.
    func reload() async {
        await attempt {
            let page = try await session.send(ProductEndpoints.review())
            products = page.items
            total = page.total
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
            hasLoaded = true
        }
    }

    /// Appends the next page.
    func loadMore() async {
        await attempt {
            let page = try await session.send(ProductEndpoints.review(page: nextPage))
            let known = Set(products.map(\.id))
            products += page.items.filter { !known.contains($0.id) }
            hasMore = page.hasMore
            nextPage = page.currentPage + 1
        }
    }

    /// Confirms a product with all its conversions and takes it off the list.
    func confirm(_ product: Product) async {
        confirmingIDs.insert(product.id)
        defer { confirmingIDs.remove(product.id) }
        await attempt {
            _ = try await session.send(ProductEndpoints.confirm(id: product.id))
            products.removeAll { $0.id == product.id }
            total = max(total - 1, 0)
        }
    }
}
