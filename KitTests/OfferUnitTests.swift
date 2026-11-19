import Foundation
import Testing
@testable import DinnertimeKit

/// The unit the size of an offer is stated in: decoding, sizes stored before units, display and the local copy.
struct OfferUnitTests {
    private let german = Locale(identifier: "de_DE")

    private func product(_ extra: String) throws -> Product {
        let json = #"{"data": {"id": 95, "name": "Avocado", "base_unit": "g", "status": "confirmed"\#(extra)}}"#
        return try ProductEndpoints.detail(id: 95).decode(Data(json.utf8))
    }

    private func offer(_ json: String) throws -> ProductOffer {
        try ProductOfferEndpoints.add(productID: 1, storeID: 1).decode(Data(#"{"data": \#(json)}"#.utf8))
    }

    @Test func readsEveryUnitAndNoneWithoutASize() throws {
        let units = try ["g", "kg", "ml", "l", "piece"].map { try offer(#"{"id": 1, "store": "Lidl", "amount": 2, "unit": "\#($0)"}"#).unit }
        let unsized = try offer(#"{"id": 1, "store": "Lidl", "amount": null, "unit": "kg"}"#)
        let unknown = try offer(#"{"id": 1, "store": "Lidl", "amount": 2, "unit": "oz"}"#)

        #expect(units == [.gram, .kilogram, .milliliter, .liter, .piece])
        #expect(OfferUnit.allCases == [.gram, .kilogram, .milliliter, .liter, .piece])
        #expect(BaseUnit.allCases.map(OfferUnit.init) == [.gram, .milliliter, .piece])
        #expect(unsized.unit == nil)
        #expect(unknown.amount == 2)
        #expect(unknown.unit == nil)
    }

    @Test func aSizeStoredBeforeUnitsReadsInTheBaseUnitOfItsProduct() throws {
        let offers = try product(#", "offers": [{"id": 3, "store": "Lidl", "amount_in_base": 225, "price": 2.59}, {"id": 4, "store": "Rewe", "amount_in_base": null}, {"id": 5, "store": "Aldi", "amount": null, "unit": null, "amount_in_base": 300}]"#).offers
        let alone = try offer(#"{"id": 3, "store": "Lidl", "amount_in_base": 225}"#)

        #expect(offers.map(\.amount) == [225, nil, nil])
        #expect(offers.map(\.unit) == [.gram, nil, nil])
        #expect(alone.amount == 225)
        #expect(alone.unit == nil)
        #expect(alone.text(amounts: AmountFormatter(locale: german), prices: PriceFormatter(currencyCode: "EUR", locale: german)) == "Lidl · 225")
    }

    @Test func theSizeOfAnOfferShowsInTheUnitItWasEnteredIn() throws {
        let amounts = AmountFormatter(locale: german)
        let prices = PriceFormatter(currencyCode: "EUR", locale: german)
        let lines = try [("0.5", "kg"), ("250", "g"), ("500", "ml"), ("1.5", "l"), ("6", "piece")].map { amount, unit in
            try offer(#"{"id": 1, "store": "Rewe", "amount": \#(amount), "unit": "\#(unit)", "price": 1.99}"#).text(amounts: amounts, prices: prices)
        }
        let pieces = String(localized: "pcs", bundle: .kit)

        #expect(lines == ["0,5 kg", "250 g", "500 ml", "1,5 l", "6 \(pieces)"].map { "Rewe · \($0) · 1,99\u{00A0}€" })
        #expect(OfferUnit.allCases.map(\.label) == ["g", "kg", "ml", "l", pieces])
    }

    @Test func aSizeAddedOfflineWithoutAUnitIsInTheBaseUnitOfTheProduct() async throws {
        let store = try await OfflineSupport.syncedStore()
        let product = try #require(await store.answer(ProductEndpoints.detail(id: 95))).response
        let sized = try await OfflineSupport.offer(at: "Lidl", for: 95, in: store, amount: 2)
        let unsized = try await OfflineSupport.offer(at: "Rewe", for: 95, in: store, unit: .kilogram, price: 1.99)
        let lidl = try await OfflineSupport.shop("Lidl", in: store)
        let cleared = try #require(await store.answer(ProductOfferEndpoints.update(id: sized.id, storeID: lidl.id, amount: nil, unit: .liter, price: nil))).response

        #expect(sized.amount == 2)
        #expect(sized.unit == OfferUnit(product.baseUnit))
        #expect(unsized.amount == nil)
        #expect(unsized.unit == nil)
        #expect(cleared.amount == nil)
        #expect(cleared.unit == nil)
    }

    @Test func aSizeTheCopyStoredBeforeUnitsShowsInTheBaseUnitAndTakesAUnitWhenCorrected() async throws {
        let store = try await OfflineSupport.syncedStore()
        let avocado: [String: Any] = [
            "id": 95, "name": "Avocado", "base_unit": "g", "status": "confirmed",
            "offers": [["id": 8, "store_id": 4, "store": "Lidl", "amount_in_base": 500, "price": 1.79]],
        ]
        _ = try await store.applySync(OfflineSupport.page(version: 130, changed: ["products": [avocado], "stores": [["id": 4, "name": "Lidl", "is_active": true]]]))
        let old = try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers
        let corrected = try #require(await store.answer(ProductOfferEndpoints.update(id: 8, storeID: 4, amount: 0.5, unit: .kilogram, price: 1.79))).response
        let cleared = try #require(await store.answer(ProductOfferEndpoints.update(id: 8, storeID: 4, amount: nil, unit: nil, price: 1.79))).response

        #expect(old.map(\.amount) == [500])
        #expect(old.map(\.unit) == [.gram])
        #expect(corrected.amount == 0.5)
        #expect(corrected.unit == .kilogram)
        #expect(cleared.amount == nil)
        #expect(try #require(await store.answer(ProductEndpoints.detail(id: 95))).response.offers == [cleared])
    }
}
