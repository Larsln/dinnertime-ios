import Foundation
import Testing
@testable import DinnertimeKit

/// The offers of a product on the local copy and on their way to the server.
struct ProductOfferOfflineTests {
    private func json(_ data: Data?) throws -> [String: Any] {
        let data = try #require(data)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func add(_ store: String, to productID: Int, in offline: OfflineStore) async throws -> ProductOffer {
        try await OfflineSupport.offer(at: store, for: productID, in: offline)
    }

    @Test func anOfferAddedOfflineShowsOnTheProductAndOnTheItemsOfTheList() async throws {
        let store = try await OfflineSupport.syncedStore()
        let lidl = try await OfflineSupport.shop("Lidl", in: store)
        let answer = try #require(await store.answer(ProductOfferEndpoints.add(productID: 95, storeID: lidl.id, amount: 1.5, unit: .kilogram, price: 2.59)))
        let offer = answer.response
        let entry = try #require(await store.pendingChanges.last)
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let items = list.items.filter { $0.product?.id == 95 }

        #expect(offer.id < 0)
        #expect(offer.store == "Lidl")
        #expect(offer.storeID == lidl.id)
        #expect(offer.isStoreActive)
        #expect(offer.amount == 1.5)
        #expect(offer.unit == .kilogram)
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
        #expect(try json(entry.body) as NSDictionary == ["store_id": lidl.id, "amount": 1.5, "unit": "kg", "price": 2.59])
    }

    @Test func anOfferChangedOfflineKeepsItsPlaceAndLosesClearedValues() async throws {
        let store = try await OfflineSupport.syncedStore()
        let first = try await OfflineSupport.offer(at: "Lidl", for: 95, in: store, amount: 2, unit: .liter, price: 2.59)
        let second = try await add("Rewe", to: 95, in: store)
        let aldi = try await OfflineSupport.shop("Aldi", in: store)
        let changed = try #require(await store.answer(ProductOfferEndpoints.update(id: first.id, storeID: aldi.id, amount: 3, unit: .piece, price: nil))).response
        let offers = try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers
        let entry = try #require(await store.pendingChanges.last)

        #expect(changed.id == first.id)
        #expect(changed.store == "Aldi")
        #expect(changed.storeID == aldi.id)
        #expect(first.unit == .liter)
        #expect(changed.amount == 3)
        #expect(changed.unit == .piece)
        #expect(changed.price == nil)
        #expect(offers == [changed, second])
        #expect(entry.method == .patch)
        #expect(entry.path == "product-offers/\(first.id)")
        #expect(entry.repairs == [.record(kind: .products, id: 95)])
    }

    @Test func aSizeSoldEverywhereIsAddedOfflineWithoutAStore() async throws {
        let store = try await OfflineSupport.syncedStore()
        let answer = try #require(await store.answer(ProductOfferEndpoints.add(productID: 95, amount: 500, unit: .gram, price: 0.99)))
        let offer = answer.response
        let entry = try #require(await store.pendingChanges.last)
        let german = Locale(identifier: "de_DE")

        #expect(offer.id < 0)
        #expect(offer.isSoldEverywhere)
        #expect(offer.store == nil)
        #expect(offer.storeID == nil)
        #expect(offer.isStoreActive)
        #expect(offer.text(amounts: AmountFormatter(locale: german), prices: PriceFormatter(currencyCode: "EUR", locale: german)) == "\(ProductOffer.everywhereLabel) · 500 g · 0,99\u{00A0}€")
        #expect(try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers == [offer])
        #expect(try #require(await store.answer(StoreEndpoints.list)).response.isEmpty)
        #expect(entry.path == "products/95/offers")
        #expect(entry.created == [offer.id])
        #expect(try json(entry.body) as NSDictionary == ["amount": 500, "unit": "g", "price": 0.99])
    }

    @Test func anOfferMovesOfflineBetweenAStoreAndEverywhere() async throws {
        let store = try await OfflineSupport.syncedStore()
        let first = try await OfflineSupport.offer(at: "Lidl", for: 95, in: store, amount: 2, unit: .piece)
        let lidl = try await OfflineSupport.shop("Lidl", in: store)
        let everywhere = try #require(await store.answer(ProductOfferEndpoints.update(id: first.id, storeID: nil, amount: 2, unit: .piece, price: nil))).response
        let entry = try #require(await store.pendingChanges.last)
        let back = try #require(await store.answer(ProductOfferEndpoints.update(id: first.id, storeID: lidl.id, amount: 2, unit: .piece, price: nil))).response

        #expect(everywhere.id == first.id)
        #expect(everywhere.isSoldEverywhere)
        #expect(everywhere.amount == 2)
        #expect(try json(entry.body)["store_id"] is NSNull)
        #expect(try #require(await store.answer(StoreEndpoints.list)).response.map(\.offerCount) == [1])
        #expect(back.store == "Lidl")
        #expect(back.storeID == lidl.id)
    }

    @Test func deletingAStoreKeepsTheSizesSoldEverywhere() async throws {
        let store = try await OfflineSupport.syncedStore()
        let everywhere = try #require(await store.answer(ProductOfferEndpoints.add(productID: 95, amount: 3, unit: .piece))).response
        _ = try await OfflineSupport.offer(at: "Lidl", for: 95, in: store)
        let lidl = try await OfflineSupport.shop("Lidl", in: store)
        _ = try await store.answer(StoreEndpoints.delete(id: lidl.id))

        #expect(try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers == [everywhere])
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
        let lidl = try await OfflineSupport.shop("Lidl", in: store)
        let rewe = try await OfflineSupport.shop("Rewe", in: store)
        _ = try await store.answer(ProductOfferEndpoints.update(id: offer.id, storeID: lidl.id, amount: nil, unit: nil, price: 1.99))
        let report = await store.drain { entry, _ in
            switch (entry.method, entry.path) {
            case (.post, "stores"): OfflineSupport.created(id: entry.created == [lidl.id] ? 71 : 72)
            case (.post, _): OfflineSupport.created(id: 501, extra: ["store_id": 71, "store": "Lidl"])
            default: .unreachable
            }
        }
        let offers = try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers
        let held = try #require(await store.answer(ProductOfferEndpoints.update(id: offer.id, storeID: rewe.id, amount: nil, unit: nil, price: nil))).response

        #expect(report.delivered == 3)
        #expect(offers.map(\.id) == [501])
        #expect(offers.first?.price == 1.99)
        #expect(await store.pendingChanges.first?.path == "product-offers/501")
        #expect(held.id == 501)
        #expect(held.store == "Rewe")
        #expect(held.storeID == 72)
    }

    @Test func offersAndTheCurrencyFromTheFeedShowWithoutAConnection() async throws {
        let store = try await OfflineSupport.syncedStore()
        let avocado: [String: Any] = [
            "id": 95, "name": "Avocado", "base_unit": "piece", "status": "confirmed",
            "offers": [["id": 8, "store_id": 4, "store": "Lidl", "amount": 2, "unit": "piece", "price": 1.79]],
        ]
        #expect(try #require(await store.answer(HouseholdSettingsEndpoints.settings)).response.currency == "EUR")

        var page = try json(OfflineSupport.page(version: 130, changed: ["products": [avocado], "stores": [["id": 4, "name": "Lidl", "is_active": true]]]))
        var body = try #require(page["data"] as? [String: Any])
        body["household"] = ["default_servings": 3, "currency": "CHF"]
        page["data"] = body
        _ = try await store.applySync(JSONSerialization.data(withJSONObject: page))
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(list.items.first { $0.product?.id == 95 }?.product?.offers.first?.price == 1.79)
        #expect(try #require(await store.answer(StoreEndpoints.list)).response.map(\.name) == ["Lidl"])
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
