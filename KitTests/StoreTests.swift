import Foundation
import Testing
@testable import DinnertimeKit

/// The shops of the household: decoding, requests, the choice when an offer is entered and what paused shops hide.
struct StoreTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func stores(_ json: String) throws -> [Store] {
        try StoreEndpoints.list.decode(Data(#"{"data": \#(json)}"#.utf8))
    }

    private func product(_ extra: String) throws -> Product {
        let json = #"{"data": {"id": 95, "name": "Avocado", "base_unit": "g", "status": "confirmed"\#(extra)}}"#
        return try ProductEndpoints.detail(id: 95).decode(Data(json.utf8))
    }

    @Test func readsTheStores() throws {
        let stores = try stores(#"[{"id": 1, "name": "Aldi", "is_active": false, "offer_count": 3}, {"id": 2, "name": "Lidl"}]"#)

        #expect(stores.map(\.id) == [1, 2])
        #expect(stores[0].name == "Aldi")
        #expect(!stores[0].isActive)
        #expect(stores[0].offerCount == 3)
        #expect(stores[1].isActive)
        #expect(stores[1].offerCount == nil)
    }

    @Test func aStoreIsPreferredOnlyWhenTheServerSaysSo() throws {
        let stores = try stores(#"[{"id": 1, "name": "Aldi", "is_preferred": true}, {"id": 2, "name": "Lidl", "is_preferred": false}, {"id": 3, "name": "Rewe"}]"#)
        let request = try builder.request(for: StoreEndpoints.setPreferred(true, id: 4))

        #expect(stores.map(\.isPreferred) == [true, false, false])
        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/v1/stores/4")
        #expect(try json(request) as NSDictionary == ["is_preferred": true])
    }

    @Test func preferredStoresComeFirstInTheListAndInTheChoice() throws {
        let stores = try stores(#"""
        [{"id": 1, "name": "Aldi", "offer_count": 1}, {"id": 2, "name": "Edeka", "is_active": false, "is_preferred": true},
        {"id": 3, "name": "Lidl", "offer_count": 4}, {"id": 4, "name": "Rewe", "is_preferred": true}, {"id": 5, "name": "Bioladen", "is_preferred": true, "offer_count": 2}]
        """#)

        #expect(stores.preferredFirst.map(\.name) == ["Bioladen", "Edeka", "Rewe", "Aldi", "Lidl"])
        #expect(stores.choices.map(\.name) == ["Bioladen", "Rewe", "Lidl", "Aldi"])
    }

    @Test func asksForTheStoresAndCreatesOne() throws {
        let list = try builder.request(for: StoreEndpoints.list)
        let creation = try builder.request(for: StoreEndpoints.create(name: "Lidl"))

        #expect(list.httpMethod == "GET")
        #expect(list.url?.path() == "/api/v1/stores")
        #expect(creation.httpMethod == "POST")
        #expect(creation.url?.path() == "/api/v1/stores")
        #expect(try json(creation) as NSDictionary == ["name": "Lidl"])
    }

    @Test func renamesPausesAndDeletesAStore() throws {
        let rename = try builder.request(for: StoreEndpoints.rename(id: 4, to: "Lidl Mitte"))
        let pause = try builder.request(for: StoreEndpoints.setActive(false, id: 4))
        let deletion = try builder.request(for: StoreEndpoints.delete(id: 4))

        #expect(rename.httpMethod == "PATCH")
        #expect(rename.url?.path() == "/api/v1/stores/4")
        #expect(try json(rename) as NSDictionary == ["name": "Lidl Mitte"])
        #expect(pause.httpMethod == "PATCH")
        #expect(pause.url?.path() == "/api/v1/stores/4")
        #expect(try json(pause) as NSDictionary == ["is_active": false])
        #expect(deletion.httpMethod == "DELETE")
        #expect(deletion.url?.path() == "/api/v1/stores/4")
        #expect(deletion.httpBody == nil)
    }

    @Test func theChoiceIsTheActiveStoresMostUsedFirstAndEquallyUsedOnesByName() throws {
        let stores = try stores(#"""
        [{"id": 1, "name": "Aldi", "offer_count": 1}, {"id": 2, "name": "Edeka", "is_active": false, "offer_count": 9},
        {"id": 3, "name": "Lidl", "offer_count": 4}, {"id": 4, "name": "Rewe", "offer_count": 1}, {"id": 5, "name": "Bioladen"}]
        """#)

        #expect(stores.choices.map(\.name) == ["Lidl", "Aldi", "Rewe", "Bioladen"])
        #expect(try self.stores("[]").choices.isEmpty)
    }

    @Test func findsAStoreByNameIgnoringCaseAndFiltersBySearch() throws {
        let stores = try stores(#"[{"id": 1, "name": "Aldi"}, {"id": 2, "name": "Lidl", "is_active": false}]"#)

        #expect(stores.first(named: " lidl ")?.id == 2)
        #expect(stores.first(named: "Li") == nil)
        #expect(stores.matching("LD").map(\.name) == ["Aldi"])
        #expect(stores.matching(" ").count == 2)
        #expect(stores.matching("x").isEmpty)
    }

    @Test func offersOfPausedStoresComeLastInTheirOrder() throws {
        let offers = try product(#"""
        , "offers": [{"id": 1, "store": "Edeka", "store_is_active": false}, {"id": 2, "store": "Lidl"},
        {"id": 3, "store": "Markt", "store_is_active": false}, {"id": 4, "store": "Aldi", "store_is_active": true}]
        """#).offers

        #expect(offers.activeFirst.map(\.id) == [2, 4, 1, 3])
        #expect(!offers.areAllPaused)
        #expect(offers.filter { !$0.isStoreActive }.areAllPaused)
        #expect(![ProductOffer]().areAllPaused)
    }

    @Test func onlyANoteOrAnOfferOfAnActiveStoreIsABuyingHint() throws {
        let paused = #"{"id": 3, "store": "Lidl", "store_id": 7, "store_is_active": false}"#

        #expect(try !product(#", "offers": [\#(paused)]"#).hasBuyingHints)
        #expect(try product(#", "note": "Bio", "offers": [\#(paused)]"#).hasBuyingHints)
        #expect(try product(#", "offers": [\#(paused), {"id": 4, "store": "Rewe", "store_id": 8}]"#).hasBuyingHints)
        #expect(try !product(#", "offers": []"#).hasBuyingHints)
    }
}
