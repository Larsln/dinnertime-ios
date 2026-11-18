import Foundation
import Testing
@testable import MealplannerKit

/// Decoding of answers recorded from a real server.
struct DecodingTests {
    @Test func serverWithoutProvider() throws {
        let info = try AuthEndpoints.server.decode(Fixture.data("server"))

        #expect(info.name == "Mealplanner")
        #expect(info.supportedLocales == ["de", "en"])
        #expect(info.oidcProvider == nil)
    }

    @Test func serverWithProvider() throws {
        let info = try AuthEndpoints.server.decode(Fixture.data("server-oidc"))

        #expect(info.oidcProvider?.clientID == "mealplanner")
        #expect(info.oidcProvider?.issuer == URL(string: "https://id.example.org/realms/home"))
    }

    @Test func signInResult() throws {
        let endpoint = AuthEndpoints.signIn(username: "a", password: "b", deviceName: "c")
        let result = try endpoint.decode(Fixture.data("sign-in"))

        #expect(result.token == "2|fixture-token")
        #expect(result.user.username == "iostest")
        #expect(result.user.email == nil)
    }

    @Test func recipePage() throws {
        let page = try RecipeEndpoints.list().decode(Fixture.data("recipes-page"))

        #expect(page.items.map(\.title) == ["Zwiebelkuchen"])
        #expect(page.currentPage == 1)
        #expect(page.total == 1)
        #expect(!page.hasMore)
        #expect(page.items[0].tags.map(\.type) == [.meal, .tag])
    }

    @Test func recipeDetail() throws {
        let recipe = try RecipeEndpoints.detail(id: 1).decode(Fixture.data("recipe"))

        #expect(recipe.summary.servings == 4)
        #expect(recipe.sourceURL == URL(string: "https://example.com/zwiebelkuchen"))
        #expect(recipe.ingredients.count == 3)
        #expect(recipe.ingredients[0].unit?.code == "g")
        #expect(recipe.ingredients[0].product?.baseUnit == .gram)
        #expect(recipe.ingredients[1].unit == nil)
        #expect(recipe.ingredients[1].isEstimated)
        #expect(recipe.ingredients[2].product == nil)
        #expect(recipe.ingredients[2].rawText == "Salz und Pfeffer")
        #expect(recipe.steps.map(\.section) == ["Belag", nil])
        #expect(recipe.tools.map(\.name) == ["Backblech"])
        #expect(recipe.tools.map(\.isOwned) == [false])
    }

    @Test func imports() throws {
        let imports = try ImportEndpoints.list.decode(Fixture.data("imports"))

        #expect(imports[0].status == .completed)
        #expect(!imports[0].isActive)
        #expect(imports[0].recipe?.id == 1)
        #expect(imports[0].createdAt == Date(timeIntervalSince1970: 1_794_950_135))
    }

    @Test func mealPlan() throws {
        let entries = try MealPlanEndpoints.entries(from: DayDate(year: 2026, month: 11, day: 16), to: DayDate(year: 2026, month: 11, day: 22))
            .decode(Fixture.data("meal-plan"))
        let cooked = try #require(entries.first { $0.id == 1 })

        #expect(cooked.date == DayDate(year: 2026, month: 11, day: 18))
        #expect(cooked.meal == .dinner)
        #expect(cooked.isCooked)
        #expect(entries.contains { !$0.isCooked })
    }

    @Test func pantry() throws {
        let items = try PantryEndpoints.list.decode(Fixture.data("pantry"))

        #expect(items[0].amount == 50)
        #expect(items[0].openedOn == DayDate(year: 2026, month: 11, day: 22))
        #expect(items[0].expiresOn == DayDate(year: 2026, month: 11, day: 27))
        #expect(items[0].product.storeSection?.key == "chilled")
    }

    @Test func productWithConversionsAndPackages() throws {
        let product = try ProductEndpoints.confirm(id: 1).decode(Fixture.data("product"))

        #expect(product.status == .confirmed)
        #expect(product.shelfLifeOpenedDays == 5)
        #expect(product.conversions?.first?.unit.code == "EL")
        #expect(product.conversions?.first?.amountInBase == 15)
        #expect(product.conversions?.last?.amountInBase == nil)
        #expect(product.packages?.first?.label == "Becher")
    }

    @Test func productPageOmitsDetailFields() throws {
        let page = try ProductEndpoints.search("zw").decode(Fixture.data("products-page"))

        #expect(page.items[0].name == "Zwiebel")
        #expect(page.items[0].baseUnit == .piece)
        #expect(page.items[0].packages == nil)
        #expect(page.items[0].recipeCount == nil)
    }

    @Test func shoppingList() throws {
        let list = try ShoppingEndpoints.current.decode(Fixture.data("shopping-list"))
        let schmand = try #require(list.items.first { $0.product?.name == "Schmand" })

        #expect(list.startsOn == DayDate(year: 2026, month: 11, day: 16))
        #expect(list.leftoversStockedAt != nil)
        #expect(schmand.isChecked)
        #expect(schmand.packages.first?.count == 2)
        #expect(schmand.leftoverAmount == 100)
        #expect(schmand.uses.first?.date == DayDate(year: 2026, month: 11, day: 18))
        #expect(schmand.purchaseText(formatter: AmountFormatter(locale: Locale(identifier: "en_US"))) == "2 × Becher 200 g + 3 Stück")
    }

    @Test func shoppingListSectionsKeepWalkingOrder() throws {
        let list = try ShoppingEndpoints.current.decode(Fixture.data("shopping-list"))
        let kinds = list.openSections.map(\.kind)

        #expect(kinds.first != .freeText)
        #expect(kinds.last == .freeText)
        #expect(list.openSections.last?.items.map(\.title) == ["Küchenrolle", "Salz und Pfeffer"])
    }

    @Test func manualItemWithoutProductAndAmounts() throws {
        let item = try ShoppingEndpoints.addItem(label: "x", listID: 1).decode(Fixture.data("manual-item"))

        #expect(item.title == "Küchenrolle")
        #expect(item.isManual)
        #expect(item.product == nil)
        #expect(!item.isApproximate)
        #expect(item.purchaseText() == nil)
    }

    @Test func tags() throws {
        let tags = try ReferenceEndpoints.tags.decode(Fixture.data("tags"))

        #expect(tags.filter { $0.type == .meal }.compactMap(\.key) == MealType.allCases.map(\.rawValue))
    }

    @Test func timestampsWithAndWithoutFractionalSeconds() throws {
        let decoder = JSONCoding.makeDecoder()
        let fractional = try decoder.decode([Date].self, from: Data(#"["2026-11-17T21:15:34.000000Z"]"#.utf8))
        let whole = try decoder.decode([Date].self, from: Data(#"["2026-11-17T21:15:34Z"]"#.utf8))

        #expect(fractional == whole)
    }

    @Test func dayDates() throws {
        let day = try #require(DayDate("2026-12-31"))

        #expect(day.adding(days: 1) == DayDate(year: 2027, month: 1, day: 1))
        #expect(day.description == "2026-12-31")
        #expect(DayDate("2026-1-1") == nil)
        #expect(DayDate("yesterday") == nil)
    }
}
