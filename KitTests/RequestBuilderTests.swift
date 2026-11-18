import Foundation
import Testing
@testable import MealplannerKit

/// Requests built from endpoints.
struct RequestBuilderTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["de-DE", "en-US"]
    )

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @Test func sendsCommonHeaders() throws {
        let request = try builder.request(for: RecipeEndpoints.detail(id: 7))

        #expect(request.url?.absoluteString == "https://meals.example.org/api/v1/recipes/7")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "Accept-Language") == "de-DE, en-US;q=0.9")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        #expect(request.httpBody == nil)
    }

    @Test func publicEndpointsCarryNoToken() throws {
        let request = try builder.request(for: AuthEndpoints.server)

        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func encodesSignInBodyInSnakeCase() throws {
        let request = try builder.request(for: AuthEndpoints.signIn(username: "anna", password: "pw", deviceName: "iPhone"))
        let body = try json(request)

        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(body as? [String: String] == ["username": "anna", "password": "pw", "device_name": "iPhone"])
    }

    @Test func encodesTokenExchangeBody() throws {
        let body = try json(builder.request(for: AuthEndpoints.signIn(idToken: "jwt", deviceName: "iPhone")))

        #expect(body as? [String: String] == ["id_token": "jwt", "device_name": "iPhone"])
    }

    @Test func buildsRecipeQuery() throws {
        let request = try builder.request(for: RecipeEndpoints.list(search: "käse kuchen", tagID: 3, course: "main", favoritesOnly: true, page: 2))
        let items = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?.queryItems

        #expect(items == [
            URLQueryItem(name: "page", value: "2"),
            URLQueryItem(name: "search", value: "käse kuchen"),
            URLQueryItem(name: "tag", value: "3"),
            URLQueryItem(name: "course", value: "main"),
            URLQueryItem(name: "favorite", value: "1"),
        ])
    }

    @Test func encodesImport() throws {
        let url = try #require(URL(string: "https://www.tiktok.com/@cook/video/1?lang=de"))
        let body = try json(builder.request(for: ImportEndpoints.create(url: url)))

        #expect(body as? [String: String] == ["url": "https://www.tiktok.com/@cook/video/1?lang=de"])
    }

    @Test func encodesMealPlanEntry() throws {
        let day = DayDate(year: 2026, month: 11, day: 18)
        let body = try json(builder.request(for: MealPlanEndpoints.create(date: day, meal: .dinner, recipeID: 4, servings: 2)))

        #expect(body["date"] as? String == "2026-11-18")
        #expect(body["meal"] as? String == "dinner")
        #expect(body["recipe_id"] as? Int == 4)
        #expect(body["servings"] as? Int == 2)
    }

    @Test func omitsMissingPantryDates() throws {
        let endpoint = PantryEndpoints.create(productID: 1, amount: 120.5, openedOn: DayDate(year: 2026, month: 11, day: 15), expiresOn: nil)
        let body = try json(builder.request(for: endpoint))

        #expect(body["product_id"] as? Int == 1)
        #expect(body["amount"] as? Double == 120.5)
        #expect(body["opened_on"] as? String == "2026-11-15")
        #expect(body["expires_on"] == nil)
    }

    @Test func encodesCheckedState() throws {
        let request = try builder.request(for: ShoppingEndpoints.setChecked(true, itemID: 9))

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/v1/shopping-list-items/9")
        #expect(try json(request)["checked"] as? Bool == true)
    }

    @Test func mealPlanPeriodQuery() throws {
        let request = try builder.request(for: MealPlanEndpoints.entries(from: DayDate(year: 2026, month: 11, day: 16), to: DayDate(year: 2026, month: 11, day: 22)))

        #expect(request.url?.query() == "from=2026-11-16&to=2026-11-22")
    }

    @Test(arguments: [
        ("meals.example.org", "https://meals.example.org"),
        (" https://meals.example.org/ ", "https://meals.example.org"),
        ("http://192.168.1.20:8000/api/v1/", "http://192.168.1.20:8000"),
        ("HTTPS://meals.example.org/kitchen?x=1", "https://meals.example.org/kitchen"),
    ])
    func normalizesServerAddresses(input: String, expected: String) {
        #expect(ServerAddress.normalize(input)?.absoluteString == expected)
    }

    @Test(arguments: ["", "ftp://meals.example.org", "https://"])
    func rejectsInvalidServerAddresses(input: String) {
        #expect(ServerAddress.normalize(input) == nil)
    }
}
