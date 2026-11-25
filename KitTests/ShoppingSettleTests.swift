import Foundation
import Testing
@testable import DinnertimeKit

/// Shopping items that are settled without buying their product: skipped ones and those replaced by a substitute.
struct ShoppingSettleTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    private func body<Response>(of endpoint: Endpoint<Response>) throws -> NSDictionary {
        let data = try #require(try builder.request(for: endpoint).httpBody)
        return try #require(JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }

    private func item(_ fields: String) throws -> ShoppingListItem {
        let json = #"{"data": {"id": 7, "label": "Tortilla", "is_manual": false, \#(fields)}}"#
        return try ShoppingEndpoints.setChecked(true, itemID: 7).decode(Data(json.utf8))
    }

    /// The first open item of the synced list that names a product.
    private func openItem(in store: OfflineStore) async throws -> ShoppingListItem {
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response
        return try #require(list.items.first { !$0.isSettled && $0.product != nil })
    }

    @Test func requestsNameWhatSettlesAnItem() throws {
        #expect(try body(of: ShoppingEndpoints.setSkipped(true, itemID: 7)) == ["skipped": true])
        #expect(try body(of: ShoppingEndpoints.setSkipped(false, itemID: 7)) == ["skipped": false])
        #expect(try body(of: ShoppingEndpoints.substitute(productID: 3, itemID: 7)) == ["checked": true, "substitute_product_id": 3])
        #expect(try body(of: ShoppingEndpoints.substitute(label: "Wraps", itemID: 7)) == ["checked": true, "substitute_label": "Wraps"])
    }

    @Test func decodesSkippedAndReplacedItems() throws {
        let skipped = try item(#""skipped_at": "2026-11-25T10:00:00.000000Z", "checked_at": null, "substitute": null"#)
        let replaced = try item(#""checked_at": "2026-11-25T10:00:00.000000Z", "substitute": {"product_id": null, "name": "Wraps"}"#)
        let open = try item(#""checked_at": null"#)

        #expect(skipped.isSkipped && skipped.isSettled && !skipped.isChecked)
        #expect(replaced.isChecked && replaced.substitute == .init(productID: nil, name: "Wraps"))
        #expect(!open.isSettled && open.substitute == nil)
    }

    @Test func aSkippedItemLeavesTheOpenSectionsOfflineAndComesBack() async throws {
        let store = try await OfflineSupport.syncedStore()
        let item = try await openItem(in: store)

        let skipped = try #require(await store.answer(ShoppingEndpoints.setSkipped(true, itemID: item.id))).response
        let list = try #require(await store.answer(ShoppingEndpoints.current)).response

        #expect(skipped.isSkipped && !skipped.isChecked)
        #expect(list.settledItems.contains { $0.id == item.id })
        #expect(!list.openSections.flatMap(\.items).contains { $0.id == item.id })
        #expect(try #require(await store.pendingChanges.last).path == "shopping-list-items/\(item.id)")

        let opened = try #require(await store.answer(ShoppingEndpoints.setSkipped(false, itemID: item.id))).response
        #expect(!opened.isSettled)
    }

    @Test func aSubstituteNamesItsProductOfflineAndIsForgottenWhenTheItemOpens() async throws {
        let store = try await OfflineSupport.syncedStore()
        let item = try await openItem(in: store)
        let other = try #require(await store.answer(ProductEndpoints.detail(id: 95))).response

        let byProduct = try #require(await store.answer(ShoppingEndpoints.substitute(productID: other.id, itemID: item.id))).response
        #expect(byProduct.isChecked)
        #expect(byProduct.substitute == .init(productID: other.id, name: other.name))

        let byName = try #require(await store.answer(ShoppingEndpoints.substitute(label: other.name.uppercased(), itemID: item.id))).response
        #expect(byName.substitute == .init(productID: other.id, name: other.name))

        let byText = try #require(await store.answer(ShoppingEndpoints.substitute(label: "Fladenbrot vom Markt", itemID: item.id))).response
        #expect(byText.substitute == .init(productID: nil, name: "Fladenbrot vom Markt"))

        let opened = try #require(await store.answer(ShoppingEndpoints.setChecked(false, itemID: item.id))).response
        #expect(!opened.isChecked && opened.substitute == nil)
    }
}
