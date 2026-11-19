import Foundation
import Testing
@testable import DinnertimeKit

/// Requests that change products, their values and the tools.
struct CatalogRequestTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @Test func searchesProductsByPage() throws {
        let request = try builder.request(for: ProductEndpoints.search("zw", page: 2))

        #expect(request.url?.path() == "/api/v1/products")
        #expect(request.url?.query() == "search=zw&page=2")
    }

    @Test func updatesProductAndClearsMissingValues() throws {
        let input = ProductInput(name: "Schmand", icon: "milk", storeSectionID: nil, baseUnit: .milliliter, isPantryStaple: true, shelfLifeOpenedDays: nil)
        let request = try builder.request(for: ProductEndpoints.update(id: 4, input))
        let body = try json(request)

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/v1/products/4")
        #expect(body["name"] as? String == "Schmand")
        #expect(body["icon"] as? String == "milk")
        #expect(body["base_unit"] as? String == "ml")
        #expect(body["is_pantry_staple"] as? Bool == true)
        #expect(body["store_section_id"] is NSNull)
        #expect(body["shelf_life_opened_days"] is NSNull)
    }

    @Test func clearsTheIconWithNull() throws {
        let input = ProductInput(name: "Schmand", icon: nil, storeSectionID: 3, baseUnit: .gram, isPantryStaple: false, shelfLifeOpenedDays: 5)
        let body = try json(builder.request(for: ProductEndpoints.update(id: 4, input)))

        #expect(body["icon"] is NSNull)
        #expect(body["store_section_id"] as? Int == 3)
    }

    @Test func householdSettings() throws {
        let settings = try HouseholdSettingsEndpoints.settings.decode(Data(#"{"data":{"default_servings":4}}"#.utf8))
        let change = try builder.request(for: HouseholdSettingsEndpoints.setDefaultServings(3))

        #expect(settings.defaultServings == 4)
        #expect(HouseholdSettings.fallbackServings == 2)
        #expect(HouseholdSettings.servingsRange == 1...50)
        #expect(change.httpMethod == "PATCH")
        #expect(change.url?.path() == "/api/v1/settings/household")
        #expect(try json(change) as? [String: Int] == ["default_servings": 3])
    }

    @Test func createsProductFromName() throws {
        let request = try builder.request(for: ProductEndpoints.create(name: "Kurkuma"))

        #expect(request.httpMethod == "POST")
        #expect(try json(request) as? [String: String] == ["name": "Kurkuma"])
    }

    @Test func mergesProduct() throws {
        let request = try builder.request(for: ProductEndpoints.merge(id: 4, into: 9))

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/v1/products/4/merge")
        #expect(try json(request) as? [String: Int] == ["into": 9])
    }

    @Test func setsConversion() throws {
        let request = try builder.request(for: ProductValueEndpoints.setConversion(productID: 4, unitID: 8, amountInBase: 12.5))

        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path() == "/api/v1/products/4/conversions/8")
        #expect(try json(request) as? [String: Double] == ["amount_in_base": 12.5])
    }

    @Test func marksUnitAsNotConvertibleWithNull() throws {
        let body = try json(builder.request(for: ProductValueEndpoints.setConversion(productID: 4, unitID: 8, amountInBase: nil)))

        #expect(body["amount_in_base"] is NSNull)
    }

    @Test func deletesConversion() throws {
        let request = try builder.request(for: ProductValueEndpoints.deleteConversion(productID: 4, unitID: 8))

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path() == "/api/v1/products/4/conversions/8")
    }

    @Test func importSettings() throws {
        let settings = try ImportSettingsEndpoints.settings.decode(Data(#"{"data":{"identify_as_browser":false,"has_cookies":true}}"#.utf8))
        let change = try builder.request(for: ImportSettingsEndpoints.setIdentifyAsBrowser(true))
        let upload = try builder.request(for: ImportSettingsEndpoints.uploadCookies(Data("# Netscape HTTP Cookie File".utf8)))
        let removal = try builder.request(for: ImportSettingsEndpoints.deleteCookies)
        let body = String(decoding: try #require(upload.httpBody), as: UTF8.self)

        #expect(!settings.identifyAsBrowser)
        #expect(settings.hasCookies)
        #expect(change.httpMethod == "PATCH")
        #expect(change.url?.path() == "/api/v1/settings/import")
        #expect(try json(change) as? [String: Bool] == ["identify_as_browser": true])
        #expect(upload.httpMethod == "POST")
        #expect(upload.url?.path() == "/api/v1/settings/import/cookies")
        #expect(body.contains("name=\"cookies\"; filename=\"cookies.txt\"\r\nContent-Type: text/plain\r\n\r\n# Netscape HTTP Cookie File\r\n"))
        #expect(removal.httpMethod == "DELETE")
        #expect(removal.url?.path() == "/api/v1/settings/import/cookies")
    }

    @Test func toolChangesOnlySendTheChangedField() throws {
        let renamed = try builder.request(for: ToolEndpoints.rename(id: 3, to: "Bratpfanne"))
        let owned = try builder.request(for: ToolEndpoints.setOwned(false, id: 3))

        #expect(renamed.httpMethod == "PATCH")
        #expect(renamed.url?.path() == "/api/v1/tools/3")
        #expect(try json(renamed) as? [String: String] == ["name": "Bratpfanne"])
        #expect(try json(owned) as? [String: Bool] == ["is_owned": false])
    }

    @Test func searchesCreatesAndMergesTools() throws {
        let search = try builder.request(for: ToolEndpoints.search("pf"))
        let create = try builder.request(for: ToolEndpoints.create(name: "Wok"))
        let merge = try builder.request(for: ToolEndpoints.merge(id: 3, into: 4))

        #expect(search.url?.query() == "search=pf")
        #expect(create.httpMethod == "POST")
        #expect(try json(create) as? [String: String] == ["name": "Wok"])
        #expect(merge.url?.path() == "/api/v1/tools/3/merge")
        #expect(try json(merge) as? [String: Int] == ["into": 4])
    }
}
