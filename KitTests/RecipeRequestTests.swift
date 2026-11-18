import Foundation
import Testing
@testable import MealplannerKit

/// Requests that change recipes and the marks of the user.
struct RecipeRequestTests {
    private let builder = RequestBuilder(
        baseURL: ServerAddress.apiBaseURL(for: URL(string: "https://meals.example.org")!),
        token: "secret",
        languages: ["en-US"]
    )

    private let input = RecipeInput(
        title: "Zwiebelkuchen",
        course: "main",
        servings: 4,
        prepMinutes: 20,
        sourceURL: "https://example.com/zwiebelkuchen",
        tagIDs: [3, 16],
        toolIDs: [1],
        ingredients: [
            RecipeInput.Ingredient(section: "Belag", productID: 1, quantity: 300, unitID: 1, note: nil, isEstimated: false, rawText: nil),
            RecipeInput.Ingredient(section: nil, productID: nil, quantity: nil, unitID: nil, note: nil, isEstimated: true, rawText: "Salz"),
        ],
        steps: [RecipeInput.Step(section: "Belag", text: "Zwiebeln anschwitzen."), RecipeInput.Step(section: nil, text: "Backen.")]
    )

    private func json(_ request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }

    @Test func ratesWithPut() throws {
        let request = try builder.request(for: RecipeMarkEndpoints.rate(7, id: 5))

        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path() == "/api/v1/recipes/5/rating")
        #expect(try json(request)["rating"] as? Int == 7)
    }

    @Test func withdrawsRatingWithNull() throws {
        let body = try json(builder.request(for: RecipeMarkEndpoints.rate(nil, id: 5)))

        #expect(body["rating"] is NSNull)
    }

    @Test func setsFavorite() throws {
        let request = try builder.request(for: RecipeMarkEndpoints.setFavorite(true, id: 5))

        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path() == "/api/v1/recipes/5/favorite")
        #expect(try json(request)["favorite"] as? Bool == true)
    }

    @Test func createsRecipeWithNestedLists() throws {
        let request = try builder.request(for: RecipeEndpoints.create(input))
        let body = try json(request)
        let ingredients = try #require(body["ingredients"] as? [[String: Any]])
        let steps = try #require(body["steps"] as? [[String: Any]])

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/v1/recipes")
        #expect(body["title"] as? String == "Zwiebelkuchen")
        #expect(body["course"] as? String == "main")
        #expect(body["prep_minutes"] as? Int == 20)
        #expect(body["source_url"] as? String == "https://example.com/zwiebelkuchen")
        #expect(body["tag_ids"] as? [Int] == [3, 16])
        #expect(body["tool_ids"] as? [Int] == [1])
        #expect(body["tools"] == nil)
        #expect(ingredients[0]["product_id"] as? Int == 1)
        #expect(ingredients[0]["unit_id"] as? Int == 1)
        #expect(ingredients[0]["quantity"] as? Double == 300)
        #expect(ingredients[1]["product_id"] is NSNull)
        #expect(ingredients[1]["raw_text"] as? String == "Salz")
        #expect(ingredients[1]["is_estimated"] as? Bool == true)
        #expect(steps[0]["section"] as? String == "Belag")
        #expect(steps[1]["section"] is NSNull)
        #expect(steps[1]["text"] as? String == "Backen.")
    }

    @Test func updateSendsEmptyValuesAsNull() throws {
        let request = try builder.request(for: RecipeEndpoints.update(id: 5, RecipeInput(title: "Tee")))
        let body = try json(request)

        #expect(request.httpMethod == "PATCH")
        #expect(request.url?.path() == "/api/v1/recipes/5")
        for key in ["description", "course", "servings", "yield_text", "prep_minutes", "cook_minutes", "source_url"] {
            #expect(body[key] is NSNull, "\(key) is not null")
        }
        #expect(body["tag_ids"] as? [Int] == [])
        #expect(body["tool_ids"] as? [Int] == [])
        #expect((body["ingredients"] as? [Any])?.isEmpty == true)
        #expect((body["steps"] as? [Any])?.isEmpty == true)
    }

    @Test func deletesRecipe() throws {
        let request = try builder.request(for: RecipeEndpoints.delete(id: 5))

        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path() == "/api/v1/recipes/5")
    }

    @Test func uploadsCoverAsMultipartForm() throws {
        let image = Data([0xFF, 0xD8, 0x00, 0x0D, 0x0A, 0xFF, 0xD9])
        let request = try builder.request(for: RecipeEndpoints.uploadCover(id: 5, jpeg: image))
        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        let boundary = try #require(contentType.split(separator: "boundary=").last.map(String.init))
        let body = try #require(request.httpBody)
        let head = "--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"cover.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n"

        #expect(request.httpMethod == "POST")
        #expect(request.url?.path() == "/api/v1/recipes/5/cover")
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        #expect(body == Data(head.utf8) + image + Data("\r\n--\(boundary)--\r\n".utf8))
    }
}
