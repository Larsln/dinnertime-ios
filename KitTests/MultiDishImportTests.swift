import Foundation
import Testing
@testable import MealplannerKit

/// Imports of videos with several dishes: decoding, the outcome and links that wait with their number of dishes.
struct MultiDishImportTests {
    private func answer(status: String = "completed", titles: [String], dishCount: Int? = nil) -> Data {
        let recipes = titles.enumerated().map { #"{"id": \#($0.offset + 3), "title": "\#($0.element)", "slug": "x", "tags": []}"# }
        let text = #"""
        {"data": {"id": 12, "url": "https://www.tiktok.com/@cook/video/1", "status": "\#(status)",
        "stage": null, "error": null, "error_message": null, "created_at": "2026-11-18T02:00:00.000000Z",
        "dish_count": \#(dishCount.map(String.init) ?? "null"),
        "recipe": \#(recipes.first ?? "null"), "recipes": [\#(recipes.joined(separator: ", "))]}}
        """#
        return Data(text.utf8)
    }

    @Test func decodesAllRecipesInOrder() throws {
        let item = try ImportEndpoints.detail(id: 12).decode(answer(titles: ["Ramen", "Gyoza", "Mochi"], dishCount: 3))

        #expect(item.recipes.map(\.title) == ["Ramen", "Gyoza", "Mochi"])
        #expect(item.recipe?.title == "Ramen")
        #expect(item.dishCount == 3)
    }

    @Test func decodesAutomaticCountAndNoRecipes() throws {
        let item = try ImportEndpoints.detail(id: 12).decode(answer(status: "processing", titles: []))

        #expect(item.recipes.isEmpty)
        #expect(item.recipe == nil)
        #expect(item.dishCount == nil)
    }

    @Test func answersWithoutTheNewFieldsFallBackToTheSingleRecipe() throws {
        let old = Data(#"""
        {"data": {"id": 12, "url": "https://example.org", "status": "completed", "error": null, "error_message": null,
        "created_at": "2026-11-18T02:00:00.000000Z", "recipe": {"id": 3, "title": "Ramen", "slug": "x", "tags": []}}}
        """#.utf8)
        let empty = Data(#"""
        {"data": {"id": 13, "url": "https://example.org", "status": "pending", "created_at": "2026-11-18T02:00:00.000000Z"}}
        """#.utf8)

        #expect(try ImportEndpoints.detail(id: 12).decode(old).recipes.map(\.title) == ["Ramen"])
        #expect(try ImportEndpoints.detail(id: 12).decode(old).dishCount == nil)
        #expect(try ImportEndpoints.detail(id: 13).decode(empty).recipes.isEmpty)
    }

    @Test func severalRecipesNotifyWithAllTitlesAndOpenTheImports() throws {
        let outcome = try #require(ImportOutcome(waitAnswer: answer(titles: ["Ramen", "Gyoza", "Mochi"], dishCount: 3)))
        let notice = try #require(outcome.notice)

        #expect(outcome == .imported(importID: 12, titles: ["Ramen", "Gyoza", "Mochi"]))
        #expect(notice.title == ImportProgress.completionTitle(recipeCount: 3))
        #expect(notice.title.contains("3"))
        #expect(notice.body == ListFormatter.localizedString(byJoining: ["Ramen", "Gyoza", "Mochi"]))
        #expect(!notice.opensRecipe)
        #expect(ImportNotice.destination(for: notice.userInfo) == .imports)
    }

    @Test func oneRecipeKeepsTheSingularHeadline() {
        #expect(ImportProgress.completionTitle(recipeCount: 1) == ImportProgress.completionTitle(recipeCount: 0))
        #expect(ImportProgress.completionTitle(recipeCount: 1) != ImportProgress.completionTitle(recipeCount: 2))
    }

    @Test func dishCountChoicesStartWithAutomatic() {
        #expect(DishCount.choices == [nil, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(DishCount.label(for: 4) == "4")
        #expect(!DishCount.label(for: nil).isEmpty)
    }

    @Test func linksWaitWithTheirDishCount() throws {
        let links = PendingLinks(directory: OfflineSupport.directory())
        let video = try #require(URL(string: "https://www.tiktok.com/@cook/video/1"))
        let page = try #require(URL(string: "https://example.org/recipe"))
        links.add(video, dishCount: 3)
        links.add(page)

        #expect(links.links == [PendingLink(url: video, dishCount: 3), PendingLink(url: page)])

        links.add(video, dishCount: 2)

        #expect(links.links == [PendingLink(url: page), PendingLink(url: video, dishCount: 2)])
    }

    @Test func linksQueuedWithoutCountStayReadable() throws {
        let directory = OfflineSupport.directory()
        let video = try #require(URL(string: "https://www.tiktok.com/@cook/video/1"))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode([video]).write(to: directory.appending(path: "pending-links.json"))
        let links = PendingLinks(directory: directory)

        #expect(links.links == [PendingLink(url: video)])

        links.add(video, dishCount: 4)

        #expect(links.links == [PendingLink(url: video, dishCount: 4)])
    }
}
