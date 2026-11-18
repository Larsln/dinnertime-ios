import Foundation
import Testing
@testable import MealplannerKit

/// Shopping items added by product: requests, the local copy, the queue and the exchange between devices.
struct ShoppingProductItemTests {
    private let acted = Date(timeIntervalSince1970: 1_795_000_000)
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    private func json(_ data: Data?) throws -> [String: Any] {
        let data = try #require(data)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func item(label: String, product: String) throws -> ShoppingListItem {
        let json = #"{"data": {"id": 7, "label": \#(label), "is_manual": true, "packages": [], "uses": [], "product": \#(product)}}"#
        return try ShoppingEndpoints.addItem(productID: 1, listID: 1).decode(Data(json.utf8))
    }

    @Test func addsAnItemByProductOrByLabel() throws {
        let byProduct = try builder.request(for: ShoppingEndpoints.addItem(productID: 95, listID: 11))
        let byLabel = try builder.request(for: ShoppingEndpoints.addItem(label: "Kerzen", listID: 11))

        #expect(byProduct.httpMethod == "POST")
        #expect(byProduct.url?.path() == "/api/v1/shopping-lists/11/items")
        #expect(try json(byProduct.httpBody) as NSDictionary == ["product_id": 95])
        #expect(try json(byLabel.httpBody) as NSDictionary == ["label": "Kerzen"])
    }

    @Test func theTitleIsTheLabelOrElseTheNameOfTheProduct() throws {
        let product = #"{"id": 95, "name": "Avocado", "icon": "avocado", "base_unit": "piece", "status": "confirmed"}"#

        #expect(try item(label: "null", product: product).title == "Avocado")
        #expect(try item(label: #""""#, product: product).title == "Avocado")
        #expect(try item(label: #""Reife Avocados""#, product: product).title == "Reife Avocados")
        #expect(try item(label: #""Kerzen""#, product: "null").title == "Kerzen")
    }

    @Test func anItemAddedOfflineByProductCarriesTheProductAndSendsItsID() async throws {
        let store = try await OfflineSupport.syncedStore()
        let answer = try #require(await store.answer(ShoppingEndpoints.addItem(productID: 95, listID: 11), now: acted))
        let entry = try #require(await store.pendingChanges.first)
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let listed = try #require(list.items.first { $0.id == answer.response.id })

        #expect(answer.response.id < 0)
        #expect(answer.response.isManual)
        #expect(answer.response.label == nil)
        #expect(answer.response.title == "Avocado")
        #expect(answer.response.product?.icon == "avocado")
        #expect(answer.response.product?.storeSection?.key == "produce")
        #expect(answer.response.purchaseText() == nil)
        #expect(listed.product?.id == 95)
        #expect(entry.path == "shopping-lists/11/items")
        #expect(entry.created == [answer.response.id])
        #expect(try json(entry.body) as NSDictionary == ["product_id": 95])
    }

    @Test func manualItemsWithAProductStandInTheAreaOfTheProduct() async throws {
        let store = try await OfflineSupport.syncedStore()
        let added = try #require(await store.answer(ShoppingEndpoints.addItem(productID: 95, listID: 11))).response
        let free = try #require(await store.answer(ShoppingEndpoints.addItem(label: "Kerzen", listID: 11))).response
        let sections = try #require(await store.answer(ShoppingEndpoints.current)).response.openSections
        let produce = try #require(sections.first { $0.items.contains { $0.id == added.id } })
        let positions = sections.compactMap { section in
            if case let .store(area) = section.kind {
                return area.position
            }
            return nil
        }

        #expect(produce.kind == .store(try #require(added.product?.storeSection)))
        #expect(produce.items.count > 1)
        #expect(sections.last?.kind == .freeText)
        #expect(sections.last?.items.map(\.id) == [free.id])
        #expect(positions == positions.sorted())
    }

    @Test func aProductThatIsOnTheListAsManualItemIsBroughtBackUnchecked() async throws {
        let store = try await OfflineSupport.syncedStore()
        let first = try #require(await store.answer(ShoppingEndpoints.addItem(productID: 95, listID: 11), now: acted)).response
        _ = try await store.answer(ShoppingEndpoints.setChecked(true, itemID: first.id), now: acted)
        let again = try #require(await store.answer(ShoppingEndpoints.addItem(productID: 95, listID: 11), now: acted)).response
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let last = try #require(await store.pendingChanges.last)

        #expect(again.id == first.id)
        #expect(!again.isChecked)
        #expect(list.items.filter { $0.isManual && $0.product?.id == 95 }.count == 1)
        #expect(last.created.isEmpty)
        #expect(last.isShoppingChange)
        #expect(try json(last.body) as NSDictionary == ["product_id": 95])
    }

    @Test func aLabelThatNamesAProductIsLinkedToIt() async throws {
        let store = try await OfflineSupport.syncedStore()
        let linked = try #require(await store.answer(ShoppingEndpoints.addItem(label: "avocado", listID: 11))).response
        let free = try #require(await store.answer(ShoppingEndpoints.addItem(label: "Kerzen", listID: 11))).response

        #expect(linked.product?.id == 95)
        #expect(linked.title == "avocado")
        #expect(free.product == nil)
        #expect(try json(await store.pendingChanges.first?.body) as NSDictionary == ["label": "avocado"])
    }

    @Test func aProductCreatedOfflineIsSentWithItsRealID() async throws {
        let store = try await OfflineSupport.syncedStore()
        let product = try #require(await store.answer(ProductEndpoints.create(name: "Kerzen"))).response
        let item = try #require(await store.answer(ShoppingEndpoints.addItem(productID: product.id, listID: 11))).response
        let sent = Recorder()
        _ = await store.drain { entry, _ in
            await sent.note(entry)
            return OfflineSupport.created(id: entry.path == "products" ? 500 : 60, extra: ["name": "Kerzen"])
        }
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(product.id < 0)
        #expect(item.product?.id == product.id)
        #expect(try json(await sent.bodies.last ?? nil) as NSDictionary == ["product_id": 500])
        #expect(list.items.first { $0.id == 60 }?.product?.id == 500)
    }

    @Test func aScreenThatStillHoldsATemporaryIDReachesTheRecord() async throws {
        let store = try await OfflineSupport.syncedStore()
        let product = try #require(await store.answer(ProductEndpoints.create(name: "Kerzen"))).response
        _ = await store.drain { _, _ in OfflineSupport.created(id: 500, extra: ["name": "Kerzen"]) }
        let read = try #require(await store.answer(ProductEndpoints.detail(id: product.id))).response
        let item = try #require(await store.answer(ShoppingEndpoints.addItem(productID: product.id, listID: 11))).response
        let entry = try #require(await store.pendingChanges.last)

        #expect(read.id == 500)
        #expect(item.product?.id == 500)
        #expect(try json(entry.body) as NSDictionary == ["product_id": 500])
    }

    @Test func anItemAddedByProductPassesToAnotherDeviceUnchanged() async throws {
        let first = try await OfflineSupport.syncedStore()
        let second = try await OfflineSupport.syncedStore()
        _ = try await first.answer(ShoppingEndpoints.addItem(productID: 95, listID: 11), now: acted)
        let changes = await first.shoppingChanges
        let areas = await second.apply(PeerCodec(peerKey: "secret").open(try PeerCodec(peerKey: "secret").seal(changes)) ?? [])
        let sent = try #require(await first.pendingChanges.first)
        let received = try #require(await second.pendingChanges.first)
        let list = try #require(await second.answer(ShoppingEndpoints.current)).response

        #expect(changes.map(\.action) == [.add(label: "Avocado", listID: 11, productID: 95)])
        #expect(areas == [.shopping])
        #expect(received.key == sent.key)
        #expect(received.clientTime == sent.clientTime)
        #expect(received.path == sent.path)
        #expect(received.body == sent.body)
        #expect(list.items.contains { $0.isManual && $0.product?.id == 95 && $0.label == nil })
    }

    @Test func aDeviceThatDoesNotKnowTheProductAddsItsName() async throws {
        let store = try await OfflineSupport.syncedStore()
        let item = PeerChange.Item(serverID: nil, creationKey: "k1")
        let change = PeerChange(key: "k1", clientTime: acted, item: item, action: .add(label: "Trüffel", listID: 11, productID: 9999))
        _ = await store.apply([change])
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(try json(await store.pendingChanges.first?.body) as NSDictionary == ["label": "Trüffel"])
        #expect(list.items.contains { $0.label == "Trüffel" && $0.product == nil })
    }

    @Test func changesOfDevicesThatOnlySendLabelsAreStillRead() throws {
        let legacy = #"{"key": "k1", "clientTime": 0, "item": {"creationKey": "k1"}, "action": {"add": {"label": "Kerzen", "listID": 11}}}"#
        let change = try JSONDecoder().decode(PeerChange.self, from: Data(legacy.utf8))

        #expect(change.action == .add(label: "Kerzen", listID: 11))
    }

    /// Notes the bodies a device sent.
    private actor Recorder {
        private(set) var bodies: [Data?] = []

        func note(_ entry: OutboxEntry) {
            bodies.append(entry.body)
        }
    }
}
