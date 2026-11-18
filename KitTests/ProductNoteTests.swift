import Foundation
import Testing
@testable import MealplannerKit

/// The note of a product: decoding, requests and the local copy.
struct ProductNoteTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    private func json(_ data: Data?) throws -> [String: Any] {
        let data = try #require(data)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func product(note: String) throws -> Product {
        let json = #"{"data": {"id": 95, "name": "Avocado", "base_unit": "piece", "status": "confirmed"\#(note)}}"#
        return try ProductEndpoints.detail(id: 95).decode(Data(json.utf8))
    }

    @Test func readsTheNoteOfAProduct() throws {
        #expect(try product(note: #", "note": "Im Bioladen, 2 Stück für 3 €""#).note == "Im Bioladen, 2 Stück für 3 €")
    }

    @Test func aProductWithoutNoteOrWithNullHasNone() throws {
        #expect(try product(note: "").note == nil)
        #expect(try product(note: #", "note": null"#).note == nil)
        #expect(try ProductEndpoints.detail(id: 1).decode(Fixture.data("product")).note == nil)
    }

    @Test func readsTheNoteOfTheProductOfAShoppingItem() throws {
        let json = #"""
        {"data": {"id": 7, "label": null, "is_manual": true, "packages": [], "uses": [],
        "product": {"id": 95, "name": "Avocado", "base_unit": "piece", "status": "confirmed", "note": "Netz mit 3 Stück"}}}
        """#
        let item = try ShoppingEndpoints.addItem(productID: 95, listID: 1).decode(Data(json.utf8))

        #expect(item.product?.note == "Netz mit 3 Stück")
    }

    @Test func setsOnlyTheNote() throws {
        let request = try builder.request(for: ProductEndpoints.setNote("Bei Edeka", id: 95))

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/v1/products/95")
        #expect(try json(request.httpBody) as NSDictionary == ["note": "Bei Edeka"])
    }

    @Test func clearsTheNoteWithNull() throws {
        let body = try json(builder.request(for: ProductEndpoints.setNote(nil, id: 95)).httpBody)

        #expect(body as NSDictionary == ["note": NSNull()])
    }

    @Test func theUpdateOfAProductCarriesItsNote() throws {
        let noted = ProductInput(name: "Schmand", icon: nil, storeSectionID: nil, baseUnit: .gram, isPantryStaple: false, shelfLifeOpenedDays: nil, note: "200 g Becher")
        let plain = ProductInput(name: "Schmand", icon: nil, storeSectionID: nil, baseUnit: .gram, isPantryStaple: false, shelfLifeOpenedDays: nil)

        #expect(try json(builder.request(for: ProductEndpoints.update(id: 4, noted)).httpBody)["note"] as? String == "200 g Becher")
        #expect(try json(builder.request(for: ProductEndpoints.update(id: 4, plain)).httpBody)["note"] is NSNull)
    }

    @Test func aNoteIsStoredTrimmedAndCutToTheLimit() {
        #expect(Product.storedNote("  Bei Edeka\n") == "Bei Edeka")
        #expect(Product.storedNote(" \n ") == nil)
        #expect(Product.storedNote(nil) == nil)
        #expect(Product.storedNote(String(repeating: "a", count: 600))?.count == Product.noteLimit)
    }

    @Test func aNoteSetOfflineShowsOnTheProductAndOnTheItemsOfTheList() async throws {
        let store = try await OfflineSupport.syncedStore()
        let answer = try #require(await store.answer(ProductEndpoints.setNote("Bei Edeka", id: 95))).response
        let entry = try #require(await store.pendingChanges.first)
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        let items = list.items.filter { $0.product?.id == 95 }

        #expect(answer.note == "Bei Edeka")
        #expect(answer.name == "Avocado")
        #expect(try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.note == "Bei Edeka")
        #expect(!items.isEmpty)
        #expect(items.allSatisfy { $0.product?.note == "Bei Edeka" })
        #expect(list.items.filter { $0.product?.id != 95 }.allSatisfy { $0.product?.note == nil })
        #expect(entry.method == .patch)
        #expect(entry.path == "products/95")
        #expect(try json(entry.body) as NSDictionary == ["note": "Bei Edeka"])
    }

    @Test func aNoteClearedOfflineLeavesTheItemsOfTheList() async throws {
        let store = try await OfflineSupport.syncedStore()
        _ = try await store.answer(ProductEndpoints.setNote("Bei Edeka", id: 95))
        let cleared = try #require(await store.answer(ProductEndpoints.setNote(nil, id: 95))).response
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(cleared.note == nil)
        #expect(list.items.filter { $0.product?.id == 95 }.allSatisfy { $0.product?.note == nil })
        #expect(try json(await store.pendingChanges.last?.body) as NSDictionary == ["note": NSNull()])
    }

    @Test func aNoteFromTheFeedShowsOnTheItemsOfTheList() async throws {
        let store = try await OfflineSupport.syncedStore()
        let avocado: [String: Any] = ["id": 95, "name": "Avocado", "base_unit": "piece", "status": "confirmed", "note": "Netz mit 3 Stück"]
        _ = try await store.applySync(OfflineSupport.page(version: 130, changed: ["products": [avocado]]))
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(list.items.first { $0.product?.id == 95 }?.product?.note == "Netz mit 3 Stück")
    }

    @Test func aProductCreatedOfflineHasNoNote() async throws {
        let store = try await OfflineSupport.syncedStore()
        let product = try #require(await store.answer(ProductEndpoints.create(name: "Kerzen"))).response

        #expect(product.note == nil)
    }
}
