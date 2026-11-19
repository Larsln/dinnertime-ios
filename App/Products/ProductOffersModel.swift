import DinnertimeKit
import Observation

/// The package sizes of one product: loads them with the shops of the household and adds, corrects and removes them.
///
/// Every change is stored at once, also without a connection.
@MainActor
@Observable
final class ProductOffersModel: ErrorReporting {
    var errorMessage: String?
    /// All shops of the household, also the paused ones.
    private(set) var stores: [Store] = []

    private var stored: [ProductOffer]
    private let session: AppSession
    private let productID: Int

    init(session: AppSession, product: Product) {
        self.session = session
        productID = product.id
        stored = product.offers
    }

    /// The offers in the order they are listed: those of paused shops last.
    var offers: [ProductOffer] {
        stored.activeFirst
    }

    /// Whether the product has offers and none of them is at a shop the household buys at.
    var hasOnlyPausedOffers: Bool {
        stored.areAllPaused
    }

    /// Names of the shops to choose from: the active ones, preferred ones first.
    var storeNames: [String] {
        stores.choices.map(\.name)
    }

    /// Loads the offers as they are stored now and the shops to choose from; on failure what is shown stays.
    func load() async {
        if let product = try? await session.send(ProductEndpoints.detail(id: productID)) {
            stored = product.offers
        }
        await loadStores()
    }

    /// Adds the offer of `draft`, or corrects the one it was made from; returns whether it was stored.
    ///
    /// A shop the household does not have yet is created from the typed name; without a name the size is sold everywhere.
    func save(_ draft: OfferDraft) async -> Bool {
        guard draft.isComplete else {
            return false
        }
        let (amount, unit, price) = (draft.amountValue, draft.unit, draft.priceValue)
        let isStored = await attempt {
            let storeID = try await storeID(named: draft.storedStore)
            if let id = draft.offerID {
                let offer = try await session.send(ProductOfferEndpoints.update(id: id, storeID: storeID, amount: amount, unit: unit, price: price))
                stored = stored.map { $0.id == id ? offer : $0 }
            } else {
                stored.append(try await session.send(ProductOfferEndpoints.add(productID: productID, storeID: storeID, amount: amount, unit: unit, price: price)))
            }
        }
        await loadStores()
        return isStored
    }

    /// Removes an offer.
    func delete(_ offer: ProductOffer) async {
        await attempt {
            try await session.send(ProductOfferEndpoints.delete(id: offer.id))
            stored.removeAll { $0.id == offer.id }
        }
        await loadStores()
    }

    /// The id of the shop called `name`, which is created if the household does not have it; `nil` without a name.
    private func storeID(named name: String?) async throws -> Int? {
        guard let name else {
            return nil
        }
        if let known = stores.first(named: name) {
            return known.id
        }
        if let listed = try await session.send(StoreEndpoints.list).first(named: name) {
            return listed.id
        }
        return try await session.send(StoreEndpoints.create(name: name)).id
    }

    private func loadStores() async {
        if let stores = try? await session.send(StoreEndpoints.list) {
            self.stores = stores
        }
    }
}
