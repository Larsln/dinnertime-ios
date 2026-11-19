import Foundation
@testable import DinnertimeKit

/// Helpers for the tests of the offline core.
enum OfflineSupport {
    /// A fresh directory for one test.
    static func directory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "offline-tests-\(UUID().uuidString)")
    }

    /// The feed recorded from a real server.
    static func feed() throws -> Data {
        try Fixture.data("sync")
    }

    /// A store filled with the recorded feed.
    static func syncedStore(in directory: URL = directory()) async throws -> OfflineStore {
        let store = OfflineStore(directory: directory)
        _ = try await store.applySync(feed())
        return store
    }

    /// A page of the feed made by hand.
    static func page(version: Int, hasMore: Bool = false, changed: [String: [[String: Any]]] = [:], deleted: [String: [Int]] = [:]) throws -> Data {
        let body: [String: Any] = [
            "version": version, "has_more": hasMore, "changed": changed, "deleted": deleted,
            "household": ["default_servings": 3], "peer_key": "key",
        ]
        return try JSONSerialization.data(withJSONObject: ["data": body])
    }

    /// A minimal recipe record.
    static func recipe(id: Int, title: String) -> [String: Any] {
        ["id": id, "title": title, "slug": title.lowercased(), "tags": [[String: Any]](), "ingredients": [[String: Any]](), "steps": [[String: Any]](), "tools": [[String: Any]](), "meal_tags_locked": false]
    }

    /// The answer of the server to a request that created a record with `id`.
    static func created(id: Int, extra: [String: Any] = [:]) -> DeliveryResult {
        let record = extra.merging(["id": id]) { _, new in new }
        return .response(status: 201, body: (try? JSONSerialization.data(withJSONObject: ["data": record])) ?? Data())
    }

    /// The shop called `name`, created on the copy if it does not hold one.
    static func shop(_ name: String, in store: OfflineStore) async throws -> Store {
        if let known = try await store.answer(StoreEndpoints.list)?.response.first(named: name) {
            return known
        }
        guard let created = try await store.answer(StoreEndpoints.create(name: name)) else {
            throw APIError.invalidResponse
        }
        return created.response
    }

    /// Adds an offer of the shop called `name` to a product, creating the shop if needed.
    static func offer(at name: String, for productID: Int, in store: OfflineStore, amount: Double? = nil, unit: OfferUnit? = nil, price: Double? = nil) async throws -> ProductOffer {
        let shop = try await shop(name, in: store)
        guard let added = try await store.answer(ProductOfferEndpoints.add(productID: productID, storeID: shop.id, amount: amount, unit: unit, price: price)) else {
            throw APIError.invalidResponse
        }
        return added.response
    }
}
