import Foundation
import Testing
@testable import MealplannerKit

/// The offers of a product on the local copy and on their way to the server.
struct ProductOfferOfflineTests {
    private func json(_ data: Data?) throws -> [String: Any] {
        let data = try #require(data)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func add(_ store: String, to productID: Int, in offline: OfflineStore) async throws -> ProductOffer {
        try #require(await offline.answer(ProductOfferEndpoints.add(productID: productID, store: store))).response
    }

    @Test func anOfferAddedOfflineShowsOnTheProductAndOnTheItemsOfTheList() async throws {
        let store = try await OfflineSupport.syncedStore()
        let answer = try #require(await store.answer(ProductOfferEndpoints.add(productID: 95, store: "Lidl", amountInBase: 2, price: 2.59)))
        let offer = answer.response
        let entry = try #require(await store.pendingChanges.first)
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let items = list.items.filter { $0.product?.id == 95 }

        #expect(offer.id < 0)
        #expect(offer.store == "Lidl")
        #expect(offer.amountInBase == 2)
        #expect(offer.price == 2.59)
        #expect(answer.areas == [.products, .shopping])
        #expect(try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers == [offer])
        #expect(!items.isEmpty)
        #expect(items.allSatisfy { $0.product?.offers == [offer] && $0.product?.hasBuyingHints == true })
        #expect(list.items.filter { $0.product?.id != 95 }.allSatisfy { $0.product?.offers.isEmpty != false })
        #expect(entry.method == .post)
        #expect(entry.path == "products/95/offers")
        #expect(entry.created == [offer.id])
        #expect(entry.repairs == [.record(kind: .products, id: 95)])
        #expect(try json(entry.body) as NSDictionary == ["store": "Lidl", "amount_in_base": 2, "price": 2.59])
    }

    @Test func anOfferChangedOfflineKeepsItsPlaceAndLosesClearedValues() async throws {
        let store = try await OfflineSupport.syncedStore()
        let first = try #require(await store.answer(ProductOfferEndpoints.add(productID: 95, store: "Lidl", amountInBase: 2, price: 2.59))).response
        let second = try await add("Rewe", to: 95, in: store)
        let changed = try #require(await store.answer(ProductOfferEndpoints.update(id: first.id, store: "Aldi", amountInBase: 3, price: nil))).response
        let offers = try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers
        let entry = try #require(await store.pendingChanges.last)

        #expect(changed.id == first.id)
        #expect(changed.store == "Aldi")
        #expect(changed.amountInBase == 3)
        #expect(changed.price == nil)
        #expect(offers == [changed, second])
        #expect(entry.method == .patch)
        #expect(entry.path == "product-offers/\(first.id)")
        #expect(entry.repairs == [.record(kind: .products, id: 95)])
    }

    @Test func anOfferDeletedOfflineLeavesTheProductAndTheItemsOfTheList() async throws {
        let store = try await OfflineSupport.syncedStore()
        let offer = try await add("Lidl", to: 95, in: store)
        let answer = try #require(await store.answer(ProductOfferEndpoints.delete(id: offer.id)))
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let entry = try #require(await store.pendingChanges.last)

        #expect(answer.areas == [.products, .shopping])
        #expect(try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers.isEmpty)
        #expect(list.items.allSatisfy { $0.product?.offers.isEmpty != false })
        #expect(entry.method == .delete)
        #expect(entry.path == "product-offers/\(offer.id)")
    }

    @Test func changingAnOfferTheCopyDoesNotHoldFails() async throws {
        let store = try await OfflineSupport.syncedStore()

        await #expect(throws: APIError.server(status: 404, message: nil)) {
            _ = try await store.answer(ProductOfferEndpoints.delete(id: 4711))
        }
        #expect(await store.pendingCount == 0)
    }

    @Test func anOfferAddedOfflineTakesTheIdOfTheServerAlsoInWaitingChanges() async throws {
        let store = try await OfflineSupport.syncedStore()
        let offer = try await add("Lidl", to: 95, in: store)
        _ = try await store.answer(ProductOfferEndpoints.update(id: offer.id, store: "Lidl", amountInBase: nil, price: 1.99))
        let report = await store.drain { entry, _ in
            entry.method == .post ? OfflineSupport.created(id: 501, extra: ["store": "Lidl"]) : .unreachable
        }
        let offers = try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers
        let held = try #require(await store.answer(ProductOfferEndpoints.update(id: offer.id, store: "Rewe", amountInBase: nil, price: nil))).response

        #expect(report.delivered == 1)
        #expect(offers.map(\.id) == [501])
        #expect(offers.first?.price == 1.99)
        #expect(await store.pendingChanges.first?.path == "product-offers/501")
        #expect(held.id == 501)
        #expect(held.store == "Rewe")
    }

    @Test func theKnownStoresAreTheMostUsedFirstAndEquallyUsedOnesByName() async throws {
        let store = try await OfflineSupport.syncedStore()
        #expect(try #require(await store.answer(ProductOfferEndpoints.stores)).response.isEmpty)

        _ = try await add("Rewe", to: 95, in: store)
        _ = try await add("Lidl", to: 95, in: store)
        _ = try await add("Lidl", to: 101, in: store)
        let aldi = try await add("Aldi", to: 101, in: store)

        #expect(try #require(await store.answer(ProductOfferEndpoints.stores)).response == ["Lidl", "Aldi", "Rewe"])

        _ = try await store.answer(ProductOfferEndpoints.delete(id: aldi.id))

        #expect(try #require(await store.answer(ProductOfferEndpoints.stores)).response == ["Lidl", "Rewe"])
    }

    @Test func offersAndTheCurrencyFromTheFeedShowWithoutAConnection() async throws {
        let store = try await OfflineSupport.syncedStore()
        let avocado: [String: Any] = [
            "id": 95, "name": "Avocado", "base_unit": "piece", "status": "confirmed",
            "offers": [["id": 8, "store": "Lidl", "amount_in_base": 2, "price": 1.79]],
        ]
        #expect(try #require(await store.answer(HouseholdSettingsEndpoints.settings)).response.currency == "EUR")

        var page = try json(OfflineSupport.page(version: 130, changed: ["products": [avocado]]))
        var body = try #require(page["data"] as? [String: Any])
        body["household"] = ["default_servings": 3, "currency": "CHF"]
        page["data"] = body
        _ = try await store.applySync(JSONSerialization.data(withJSONObject: page))
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(list.items.first { $0.product?.id == 95 }?.product?.offers.first?.price == 1.79)
        #expect(try #require(await store.answer(ProductOfferEndpoints.stores)).response == ["Lidl"])
        #expect(try #require(await store.answer(HouseholdSettingsEndpoints.settings)).response.currency == "CHF")
    }

    @Test func aProductCreatedOfflineHasNoOffersAndTakesOne() async throws {
        let store = try await OfflineSupport.syncedStore()
        let product = try #require(await store.answer(ProductEndpoints.create(name: "Kerzen"))).response
        let offer = try await add("Drogerie", to: product.id, in: store)

        #expect(product.offers.isEmpty)
        #expect(try #require(await store.answer(ProductEndpoints.detail(id: product.id))).response.offers == [offer])
    }
}
