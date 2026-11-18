import MealplannerKit
import Observation

/// The offers of one product: loads them with the shops in use and adds, corrects and removes them.
///
/// Every change is stored at once, also without a connection.
@MainActor
@Observable
final class ProductOffersModel: ErrorReporting {
    var errorMessage: String?
    private(set) var offers: [ProductOffer]
    /// Names of the shops used so far, most used first.
    private(set) var stores: [String] = []

    private let session: AppSession
    private let productID: Int

    init(session: AppSession, product: Product) {
        self.session = session
        productID = product.id
        offers = product.offers
    }

    /// Loads the offers as they are stored now and the shops to choose from; on failure what is shown stays.
    func load() async {
        if let product = try? await session.send(ProductEndpoints.detail(id: productID)) {
            offers = product.offers
        }
        await loadStores()
    }

    /// Adds the offer of `draft`, or corrects the one it was made from; returns whether it was stored.
    func save(_ draft: OfferDraft) async -> Bool {
        guard draft.isComplete, let store = draft.storedStore else {
            return false
        }
        let (amount, price) = (draft.amountValue, draft.priceValue)
        let isStored = await attempt {
            if let id = draft.offerID {
                let offer = try await session.send(ProductOfferEndpoints.update(id: id, store: store, amountInBase: amount, price: price))
                offers = offers.map { $0.id == id ? offer : $0 }
            } else {
                offers.append(try await session.send(ProductOfferEndpoints.add(productID: productID, store: store, amountInBase: amount, price: price)))
            }
        }
        await loadStores()
        return isStored
    }

    /// Removes an offer.
    func delete(_ offer: ProductOffer) async {
        await attempt {
            try await session.send(ProductOfferEndpoints.delete(id: offer.id))
            offers.removeAll { $0.id == offer.id }
        }
        await loadStores()
    }

    private func loadStores() async {
        if let stores = try? await session.send(ProductOfferEndpoints.stores) {
            self.stores = stores
        }
    }
}
