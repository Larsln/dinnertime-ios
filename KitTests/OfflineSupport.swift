import Foundation
@testable import MealplannerKit

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
}
