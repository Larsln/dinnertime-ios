import Foundation
import Testing
@testable import DinnertimeKit

/// Decoding of courses, marks, tools and the values of a product.
struct CatalogDecodingTests {
    @Test func courses() throws {
        let courses = try ReferenceEndpoints.courses.decode(Fixture.data("courses"))

        #expect(courses.count == 9)
        #expect(courses.first == Course(key: "starter", name: "Vorspeise"))
        #expect(courses.map(\.id).contains("main"))
    }

    @Test func recipeWithCourseAndMarks() throws {
        let summary = try RecipeEndpoints.detail(id: 1).decode(Fixture.data("recipe")).summary

        #expect(summary.course == "main")
        #expect(summary.courseName == "Hauptgericht")
        #expect(summary.rating == 8)
        #expect(summary.isFavorite)
        #expect(summary.averageRating == 7.5)
        #expect(summary.ratingCount == 2)
    }

    @Test func recipeOnAListWithoutMarks() throws {
        let summary = try RecipeEndpoints.list().decode(Fixture.data("recipes-page")).items[0]

        #expect(summary.course == "main")
        #expect(summary.rating == nil)
        #expect(!summary.isFavorite)
        #expect(summary.averageRating == nil)
        #expect(summary.ratingCount == 0)
    }

    @Test func embeddedRecipeReadsAsUnmarked() throws {
        let entries = try MealPlanEndpoints.entries(from: DayDate(year: 2026, month: 11, day: 16), to: DayDate(year: 2026, month: 11, day: 22))
            .decode(Fixture.data("meal-plan"))

        #expect(entries[0].recipe.rating == nil)
        #expect(!entries[0].recipe.isFavorite)
        #expect(entries[0].recipe.ratingCount == 0)
    }

    @Test func ratingAnswersWithTheSummary() throws {
        let summary = try RecipeMarkEndpoints.rate(8, id: 1).decode(Fixture.data("recipe"))

        #expect(summary.rating == 8)
    }

    @Test func toolCatalog() throws {
        let tools = try ToolEndpoints.search("pfanne").decode(Fixture.data("tools"))

        #expect(tools.map(\.name) == ["Pfanne", "Pfanne mit Deckel", "Pfannenwender"])
        #expect(tools[0].isOwned)
        #expect(tools[0].recipeCount == 5)
    }

    @Test func toolOfARecipeCarriesNoRecipeCount() throws {
        let tool = try #require(RecipeEndpoints.detail(id: 1).decode(Fixture.data("recipe")).tools.first)

        #expect(!tool.isOwned)
        #expect(tool.recipeCount == nil)
    }

    @Test func productDetail() throws {
        let product = try ProductEndpoints.detail(id: 1).decode(Fixture.data("product"))
        let conversions = try #require(product.conversions)

        #expect(product.recipeCount == 1)
        #expect(product.storeSection?.name == "Kühlregal")
        #expect(product.aliases == [])
        #expect(product.offers.map(\.amount) == [200, 0.5])
        #expect(conversions.map(\.amountInBase) == [15, nil])
        #expect(conversions[1].unit.code == "Stück")
        #expect(conversions[1].status == .suggested)
    }

    @Test func shoppingItemWithExtraAmounts() throws {
        let list = try ShoppingEndpoints.current.decode(Fixture.data("shopping-list"))
        let schmand = try #require(list.items.first { $0.product?.name == "Schmand" })
        let onions = try #require(list.items.first { $0.product?.name == "Zwiebel" })

        #expect(schmand.extraAmounts == [ShoppingListItem.ExtraAmount(quantity: 3, unitCode: "Stück")])
        #expect(onions.extraAmounts.isEmpty)
    }

    @Test func aSuggestedStapleOnlyCountsOnceTheProductIsConfirmed() throws {
        func product(status: String, staple: Bool) throws -> Product {
            let json = #"{"data": {"id": 1, "name": "Öl", "base_unit": "ml", "is_pantry_staple": \#(staple), "status": "\#(status)"}}"#
            return try ProductEndpoints.detail(id: 1).decode(Data(json.utf8))
        }

        #expect(try product(status: "confirmed", staple: true).isStaple)
        #expect(try !product(status: "suggested", staple: true).isStaple)
        #expect(try !product(status: "confirmed", staple: false).isStaple)
    }
}
