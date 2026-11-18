import Foundation
import Testing
@testable import MealplannerKit

/// The offers of a product: decoding, requests and display.
struct ProductOfferTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )
    private let german = Locale(identifier: "de_DE")
    private let english = Locale(identifier: "en_US")

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    private func product(_ extra: String) throws -> Product {
        let json = #"{"data": {"id": 95, "name": "Avocado", "base_unit": "g", "status": "confirmed"\#(extra)}}"#
        return try ProductEndpoints.detail(id: 95).decode(Data(json.utf8))
    }

    private func offer(_ json: String) throws -> ProductOffer {
        try ProductOfferEndpoints.add(productID: 1, store: "x").decode(Data(#"{"data": \#(json)}"#.utf8))
    }

    @Test func readsTheOffersOfAProduct() throws {
        let offers = try product(#", "offers": [{"id": 3, "store": "Lidl", "amount_in_base": 225, "price": 2.59}, {"id": 4, "store": "Rewe", "amount_in_base": null, "price": null}]"#).offers

        #expect(offers.map(\.id) == [3, 4])
        #expect(offers[0].store == "Lidl")
        #expect(offers[0].amountInBase == 225)
        #expect(offers[0].price == 2.59)
        #expect(offers[1].amountInBase == nil)
        #expect(offers[1].price == nil)
    }

    @Test func aProductWithoutTheKeyHasNoOffers() throws {
        #expect(try product("").offers.isEmpty)
        #expect(try ProductEndpoints.detail(id: 1).decode(Fixture.data("product")).offers.isEmpty)
        #expect(try ProductEndpoints.search("").decode(Fixture.data("products-page")).items.allSatisfy(\.offers.isEmpty))
    }

    @Test func readsAPriceWrittenAsDecimalText() throws {
        let offer = try offer(#"{"id": 3, "store": "Lidl", "price": "2.59"}"#)

        #expect(offer.price == 2.59)
        #expect(offer.amountInBase == nil)
    }

    @Test func readsTheOffersOfTheProductOfAShoppingItem() throws {
        let json = #"""
        {"data": {"id": 7, "label": null, "is_manual": true, "packages": [], "uses": [],
        "product": {"id": 95, "name": "Avocado", "base_unit": "piece", "status": "confirmed", "offers": [{"id": 3, "store": "Lidl", "amount_in_base": 2, "price": 1.79}]}}}
        """#
        let item = try ShoppingEndpoints.addItem(productID: 95, listID: 1).decode(Data(json.utf8))

        #expect(item.product?.offers.first?.store == "Lidl")
    }

    @Test func aNoteOrAnOfferIsABuyingHint() throws {
        #expect(try !product("").hasBuyingHints)
        #expect(try product(#", "note": "Bio""#).hasBuyingHints)
        #expect(try product(#", "offers": [{"id": 3, "store": "Lidl"}]"#).hasBuyingHints)
    }

    @Test func addsAnOfferWithoutTheMissingValues() throws {
        let full = try builder.request(for: ProductOfferEndpoints.add(productID: 95, store: "Lidl", amountInBase: 225, price: 2.59))
        let bare = try builder.request(for: ProductOfferEndpoints.add(productID: 95, store: "Lidl"))

        #expect(full.httpMethod == "POST")
        #expect(full.url?.path() == "/api/v1/products/95/offers")
        #expect(try json(full) as NSDictionary == ["store": "Lidl", "amount_in_base": 225, "price": 2.59])
        #expect(try json(bare) as NSDictionary == ["store": "Lidl"])
    }

    @Test func correctsAnOfferAndClearsMissingValuesWithNull() throws {
        let request = try builder.request(for: ProductOfferEndpoints.update(id: 3, store: "Rewe", amountInBase: nil, price: 1.99))

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/v1/product-offers/3")
        #expect(try json(request) as NSDictionary == ["store": "Rewe", "amount_in_base": NSNull(), "price": 1.99])
    }

    @Test func deletesAnOfferAndAsksForTheStores() throws {
        let deletion = try builder.request(for: ProductOfferEndpoints.delete(id: 3))
        let stores = try builder.request(for: ProductOfferEndpoints.stores)

        #expect(deletion.httpMethod == "DELETE")
        #expect(deletion.url?.path() == "/api/v1/product-offers/3")
        #expect(stores.httpMethod == "GET")
        #expect(stores.url?.path() == "/api/v1/stores")
        #expect(try ProductOfferEndpoints.stores.decode(Data(#"{"data": ["Lidl", "Rewe"]}"#.utf8)) == ["Lidl", "Rewe"])
    }

    @Test func householdSettingsCarryTheCurrency() throws {
        let stated = try HouseholdSettingsEndpoints.settings.decode(Data(#"{"data":{"default_servings":4,"currency":"CHF"}}"#.utf8))
        let silent = try HouseholdSettingsEndpoints.settings.decode(Data(#"{"data":{"default_servings":4}}"#.utf8))

        #expect(stated.currency == "CHF")
        #expect(silent.currency == "EUR")
    }

    @Test func formatsPricesInTheCurrencyOfTheHousehold() {
        #expect(PriceFormatter(currencyCode: "EUR", locale: german).string(2.59) == "2,59\u{00A0}€")
        #expect(PriceFormatter(currencyCode: "EUR", locale: german).string(3) == "3,00\u{00A0}€")
        #expect(PriceFormatter(currencyCode: "USD", locale: english).string(2.5) == "$2.50")
        #expect(PriceFormatter(currencyCode: "EUR", locale: german).symbol == "€")
        #expect(PriceFormatter(currencyCode: "USD", locale: english).symbol == "$")
    }

    @Test func anOfferIsShownInOneLineWithoutItsMissingParts() throws {
        let amounts = AmountFormatter(locale: german)
        let prices = PriceFormatter(currencyCode: "EUR", locale: german)
        let full = try offer(#"{"id": 1, "store": "Lidl", "amount_in_base": 225, "price": 2.59}"#)
        let priced = try offer(#"{"id": 2, "store": "Rewe", "amount_in_base": null, "price": 1.5}"#)
        let sized = try offer(#"{"id": 3, "store": "Aldi", "amount_in_base": 1500}"#)
        let bare = try offer(#"{"id": 4, "store": "Markt"}"#)

        #expect(full.text(unit: .gram, amounts: amounts, prices: prices) == "Lidl · 225 g · 2,59\u{00A0}€")
        #expect(priced.text(unit: .gram, amounts: amounts, prices: prices) == "Rewe · 1,50\u{00A0}€")
        #expect(sized.text(unit: .gram, amounts: amounts, prices: prices) == "Aldi · 1,5 kg")
        #expect(bare.text(unit: .gram, amounts: amounts, prices: prices) == "Markt")
    }

    @Test func readsTypedNumbersWithCommaOrPoint() {
        #expect(NumberInput.value("225") == 225)
        #expect(NumberInput.value(" 2,59 ") == 2.59)
        #expect(NumberInput.value("2.59") == 2.59)
        #expect(NumberInput.value("") == nil)
        #expect(NumberInput.value("2,5,9") == nil)
        #expect(NumberInput.value("-1") == nil)
        #expect(NumberInput.price("2,599") == 2.6)
        #expect(AmountFormatter(locale: german).input(2.5) == "2,5")
        #expect(AmountFormatter(locale: german).input(nil) == "")
    }

    @Test func theNameOfAShopIsStoredTrimmedAndCutToTheLimit() {
        #expect(ProductOffer.storedStore("  Lidl\n") == "Lidl")
        #expect(ProductOffer.storedStore("  ") == nil)
        #expect(ProductOffer.storedStore(String(repeating: "a", count: 120))?.count == ProductOffer.storeLimit)
    }
}
