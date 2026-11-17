import MealplannerKit
import Observation

/// Searches the products of the household by name or alias.
@MainActor
@Observable
final class ProductSearchModel: ErrorReporting {
    var searchText = ""
    var errorMessage: String?
    private(set) var products: [Product] = []
    private(set) var hasLoaded = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Loads the products that match the search text.
    func search() async {
        await attempt {
            products = try await session.send(ProductEndpoints.search(searchText)).items
            hasLoaded = true
        }
    }
}
