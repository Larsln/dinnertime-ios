import Foundation
import Testing
@testable import DinnertimeKit

/// The shops on the local copy: what the feed brings, changes made offline and what they do to the offers of the products.
struct StoreOfflineTests {
    /// Collects the changes a drain sent.
    private actor Sent {
        private(set) var entries: [OutboxEntry] = []

        func add(_ entry: OutboxEntry) {
            entries.append(entry)
        }
    }

    private func json(_ data: Data?) throws -> [String: Any] {
        let data = try #require(data)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func stores(in store: OfflineStore) async throws -> [Store] {
        try #require(await store.answer(StoreEndpoints.list)).response
    }

    private func offers(of productID: Int, in store: OfflineStore) async throws -> [ProductOffer] {
        try #require(await store.answer(ProductEndpoints.detail(id: productID))).response.offers
    }

    private func avocado(offers: [[String: Any]]) -> [String: Any] {
        ["id": 95, "name": "Avocado", "base_unit": "piece", "status": "confirmed", "offers": offers]
    }

    /// A store that got two shops and an offer of each for the avocado from the feed.
    private func storeWithShops() async throws -> OfflineStore {
        let store = try await OfflineSupport.syncedStore()
        let shops: [[String: Any]] = [["id": 4, "name": "Lidl", "is_active": true, "offer_count": 1], ["id": 5, "name": "Aldi", "is_active": true, "offer_count": 1]]
        let offers: [[String: Any]] = [["id": 8, "store_id": 4, "store": "Lidl", "price": 1.79], ["id": 9, "store_id": 5, "store": "Aldi", "price": 1.49]]
        _ = try await store.applySync(OfflineSupport.page(version: 130, changed: ["stores": shops, "products": [avocado(offers: offers)]]))
        return store
    }

    @Test func storesFromTheFeedAreListedByNameWithTheirOffersCounted() async throws {
        let store = try await OfflineSupport.syncedStore()
        #expect(try await stores(in: store).isEmpty)

        let shops: [[String: Any]] = [["id": 4, "name": "Lidl", "is_active": true], ["id": 5, "name": "Aldi", "is_active": false]]
        let offers: [[String: Any]] = [["id": 8, "store_id": 4, "store": "Lidl"], ["id": 9, "store_id": 4, "store": "Lidl", "amount": 2, "unit": "piece"]]
        let progress = try await store.applySync(OfflineSupport.page(version: 130, changed: ["stores": shops, "products": [avocado(offers: offers)]]))
        let listed = try await stores(in: store)

        #expect(progress.areas == [.products, .shopping])
        #expect(listed.map(\.name) == ["Aldi", "Lidl"])
        #expect(listed.map(\.isActive) == [false, true])
        #expect(listed.map(\.offerCount) == [0, 2])
    }

    @Test func aStoreRenamedOrPausedElsewhereShowsOnTheOffersWithoutTheProducts() async throws {
        let store = try await storeWithShops()
        let progress = try await store.applySync(OfflineSupport.page(version: 131, changed: ["stores": [["id": 4, "name": "Lidl Mitte", "is_active": false]]]))
        let offers = try await offers(of: 95, in: store)
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(progress.areas == [.products, .shopping])
        #expect(offers.map(\.store) == ["Lidl Mitte", "Aldi"])
        #expect(offers.map(\.isStoreActive) == [false, true])
        #expect(list.items.first { $0.product?.id == 95 }?.product?.offers.first?.store == "Lidl Mitte")
    }

    @Test func aStoreDeletedElsewhereTakesItsOffersAlong() async throws {
        let store = try await storeWithShops()
        _ = try await store.applySync(OfflineSupport.page(version: 131, deleted: ["stores": [4]]))

        #expect(try await stores(in: store).map(\.name) == ["Aldi"])
        #expect(try await offers(of: 95, in: store).map(\.id) == [9])
    }

    @Test func aStoreCreatedOfflineIsActiveAndQueued() async throws {
        let store = try await OfflineSupport.syncedStore()
        let answer = try #require(await store.answer(StoreEndpoints.create(name: "Lidl")))
        let entry = try #require(await store.pendingChanges.first)

        #expect(answer.response.id < 0)
        #expect(answer.response.isActive)
        #expect(answer.response.offerCount == 0)
        #expect(answer.areas == [.products])
        #expect(try await stores(in: store) == [answer.response])
        #expect(entry.method == .post)
        #expect(entry.path == "stores")
        #expect(entry.created == [answer.response.id])
        #expect(entry.createdKind == .stores)
        #expect(entry.repairs == [.kind(.stores)])
        #expect(try json(entry.body) as NSDictionary == ["name": "Lidl"])
    }

    @Test func aNameThatExistsIgnoringCaseIsTurnedAway() async throws {
        let store = try await storeWithShops()

        await #expect(throws: APIError.self) {
            _ = try await store.answer(StoreEndpoints.create(name: "lidl"))
        }
        await #expect(throws: APIError.self) {
            _ = try await store.answer(StoreEndpoints.rename(id: 5, to: "LIDL"))
        }
        #expect(try #require(await store.answer(StoreEndpoints.rename(id: 4, to: "LIDL"))).response.name == "LIDL")
        #expect(await store.pendingCount == 1)
    }

    @Test func aStorePausedOfflineHidesItsOffersFromTheMarkOfTheTile() async throws {
        let store = try await storeWithShops()
        _ = try await store.answer(StoreEndpoints.setActive(false, id: 5))
        let answer = try #require(await store.answer(StoreEndpoints.setActive(false, id: 4)))
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let item = try #require(list.items.first { $0.product?.id == 95 })
        let entry = try #require(await store.pendingChanges.last)

        #expect(!answer.response.isActive)
        #expect(answer.response.offerCount == 1)
        #expect(answer.areas == [.products, .shopping])
        #expect(item.product?.offers.count == 2)
        #expect(item.product?.offers.areAllPaused == true)
        #expect(item.product?.hasBuyingHints == false)
        #expect(entry.method == .patch)
        #expect(entry.path == "stores/4")
        #expect(entry.repairs == [.kind(.stores)])
        #expect(try json(entry.body) as NSDictionary == ["is_active": false])

        _ = try await store.answer(StoreEndpoints.setActive(true, id: 4))
        let shown = try await offers(of: 95, in: store)

        #expect(shown.map(\.isStoreActive) == [true, false])
        #expect(shown.activeFirst.map(\.id) == [8, 9])
        #expect(try #require(await store.answer(ProductEndpoints.search("Avocado"))).response.items.first?.hasBuyingHints == true)
    }

    @Test func aStoreRenamedOfflineShowsItsNewNameOnTheOffers() async throws {
        let store = try await storeWithShops()
        let renamed = try #require(await store.answer(StoreEndpoints.rename(id: 4, to: "Lidl Mitte"))).response
        let entry = try #require(await store.pendingChanges.last)

        #expect(renamed.name == "Lidl Mitte")
        #expect(renamed.isActive)
        #expect(try await stores(in: store).map(\.name) == ["Aldi", "Lidl Mitte"])
        #expect(try await offers(of: 95, in: store).map(\.store) == ["Lidl Mitte", "Aldi"])
        #expect(entry.path == "stores/4")
        #expect(try json(entry.body) as NSDictionary == ["name": "Lidl Mitte"])
    }

    @Test func aStoreDeletedOfflineTakesItsOffersOffTheProducts() async throws {
        let store = try await storeWithShops()
        _ = try await OfflineSupport.offer(at: "Lidl", for: 101, in: store)
        let answer = try #require(await store.answer(StoreEndpoints.delete(id: 4)))
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let entry = try #require(await store.pendingChanges.last)

        #expect(answer.areas == [.products, .shopping])
        #expect(try await stores(in: store).map(\.name) == ["Aldi"])
        #expect(try await offers(of: 95, in: store).map(\.id) == [9])
        #expect(try await offers(of: 101, in: store).isEmpty)
        #expect(list.items.first { $0.product?.id == 95 }?.product?.offers.map(\.id) == [9])
        #expect(entry.method == .delete)
        #expect(entry.path == "stores/4")
        #expect(entry.repairs == [.kind(.stores), .record(kind: .products, id: 95), .record(kind: .products, id: 101)])
        await #expect(throws: APIError.server(status: 404, message: nil)) {
            _ = try await store.answer(StoreEndpoints.delete(id: 4))
        }
    }

    @Test func anOfferNeedsAStoreTheCopyHolds() async throws {
        let store = try await OfflineSupport.syncedStore()

        await #expect(throws: APIError.server(status: 404, message: nil)) {
            _ = try await store.answer(ProductOfferEndpoints.add(productID: 95, storeID: 4711))
        }
        #expect(await store.pendingCount == 0)
    }

    @Test func anOfferOfAStoreCreatedOfflineIsSentWithTheIdOfTheServer() async throws {
        let store = try await OfflineSupport.syncedStore()
        let offer = try await OfflineSupport.offer(at: "Lidl", for: 95, in: store, price: 1.79)
        let temporary = try #require(offer.storeID)
        _ = try await store.answer(StoreEndpoints.setActive(false, id: temporary))
        let sent = Sent()
        let report = await store.drain { entry, _ in
            await sent.add(entry)
            switch entry.path {
            case "stores": return OfflineSupport.created(id: 40, extra: ["name": "Lidl", "is_active": true, "offer_count": 0])
            case "products/95/offers": return OfflineSupport.created(id: 501, extra: ["store_id": 40, "store": "Lidl", "price": 1.79])
            default: return .response(status: 200, body: Data(#"{"data": {"id": 40, "name": "Lidl", "is_active": false}}"#.utf8))
            }
        }
        let entries = await sent.entries
        let shown = try await offers(of: 95, in: store)
        let listed = try await stores(in: store)

        #expect(temporary < 0)
        #expect(report.delivered == 3)
        #expect(entries.map(\.path) == ["stores", "products/95/offers", "stores/40"])
        #expect(try json(entries[1].body) as NSDictionary == ["store_id": 40, "price": 1.79])
        #expect(shown.map(\.id) == [501])
        #expect(shown.first?.storeID == 40)
        #expect(shown.first?.isStoreActive == false)
        #expect(listed.map(\.id) == [40])
        #expect(listed.first?.isActive == false)
        #expect(listed.first?.offerCount == 1)
        #expect(try #require(await store.answer(StoreEndpoints.rename(id: temporary, to: "Lidl Mitte"))).response.id == 40)
    }

    @Test func aStoreTheServerTurnsAwayLeavesTheCopy() async throws {
        let store = try await storeWithShops()
        _ = try await store.answer(StoreEndpoints.create(name: "Rewe"))
        let report = await store.drain { _, _ in
            .response(status: 422, body: Data(#"{"message":"The name has already been taken."}"#.utf8))
        }

        #expect(report.rejections == ["The name has already been taken."])
        #expect(try await stores(in: store).map(\.name) == ["Aldi", "Lidl"])
        #expect(await store.pendingRepairs == [.kind(.stores)])
    }

    @Test func theStoresSurviveARestart() async throws {
        let directory = OfflineSupport.directory()
        let store = try await OfflineSupport.syncedStore(in: directory)
        _ = try await store.applySync(OfflineSupport.page(version: 130, changed: ["stores": [["id": 4, "name": "Lidl", "is_active": false]]]))
        _ = try await store.answer(StoreEndpoints.create(name: "Aldi"))
        let reopened = OfflineStore(directory: directory)

        #expect(try await stores(in: reopened).map(\.name) == ["Aldi", "Lidl"])
        #expect(try await stores(in: reopened).map(\.isActive) == [true, false])
    }
}
