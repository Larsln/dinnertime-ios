import Foundation
import Testing
@testable import DinnertimeKit

/// Sides as the server sends them and as the screens tell them from meals.
struct SideTests {
    private func entries(_ records: [[String: Any]]) throws -> [MealPlanEntry] {
        let data = try JSONSerialization.data(withJSONObject: ["data": records])
        return try MealPlanEndpoints.entries(from: SideSupport.day, to: SideSupport.day).decode(data)
    }

    @Test func recipesNameTheirKindAndTheKindsTheyAreServedWith() throws {
        let plan = try entries([
            SideSupport.entry(10, recipe: SideSupport.schnitzel),
            SideSupport.entry(11, recipe: SideSupport.fries, parent: 10),
        ])

        #expect(plan[0].recipe.sideOptions == ["potato", "rice"])
        #expect(plan[0].recipe.sideKind == nil)
        #expect(plan[0].recipe.takesSides)
        #expect(plan[0].parentID == nil)
        #expect(plan[1].recipe.sideKind == "potato")
        #expect(plan[1].recipe.isSide(for: plan[0].recipe))
        #expect(!plan[0].recipe.isSide(for: plan[1].recipe))
        #expect(plan[1].parentID == 10)
    }

    @Test func answersOfAnOlderServerReadAsWithoutSides() throws {
        let record = SideSupport.entry(10, recipe: SideSupport.schnitzel).filter { $0.key != "parent_id" }
            .merging(["recipe": OfflineSupport.recipe(id: 1, title: "Schnitzel")]) { _, new in new }
        let entry = try #require(try entries([record]).first)

        #expect(entry.parentID == nil)
        #expect(entry.recipe.sideKind == nil)
        #expect(entry.recipe.sideOptions.isEmpty)
        #expect(!entry.recipe.takesSides)
    }

    @Test func theKindsOfSideAreDecoded() throws {
        let json = #"{"data": [{"key": "potato", "name": "Kartoffeln"}, {"key": "rice", "name": "Reis"}]}"#
        let kinds = try ReferenceEndpoints.sideKinds.decode(Data(json.utf8))

        #expect(kinds.map(\.key) == ["potato", "rice"])
        #expect(kinds.first?.name == "Kartoffeln")
        #expect(ReferenceEndpoints.sideKinds.path == "side-kinds")
    }

    @Test func sidesAreListedWithTheirMealAndNotAsMeals() throws {
        let plan = try entries([
            SideSupport.entry(10, recipe: SideSupport.schnitzel),
            SideSupport.entry(12, recipe: SideSupport.rice, parent: 10),
            SideSupport.entry(-3, recipe: SideSupport.bakedPotatoes, parent: 10),
            SideSupport.entry(11, recipe: SideSupport.fries, parent: 10),
            SideSupport.entry(13, recipe: SideSupport.rice, parent: 99),
        ])

        #expect(plan.meals.map(\.id) == [10, 13])
        #expect(plan.sides(of: plan[0]).map(\.id) == [11, 12, -3])
        #expect(plan.sides(of: plan[4]).isEmpty)
    }

    @Test func theNextMealToCookIsNeverASide() throws {
        let plan = try entries([
            SideSupport.entry(11, recipe: SideSupport.fries, parent: 12),
            SideSupport.entry(12, recipe: SideSupport.schnitzel),
        ])

        #expect(plan.nextMeal(from: SideSupport.day)?.id == 12)
    }

    @Test func aRecipeSendsItsKindAndTheKindsItIsServedWith() throws {
        let dish = try #require(try JSONValue.object(from: JSONCoding.makeEncoder().encode(RecipeInput(title: "Schnitzel", sideOptions: ["potato"]))))
        let side = try #require(try JSONValue.object(from: JSONCoding.makeEncoder().encode(RecipeInput(title: "Fritten", sideKind: "potato"))))

        #expect(dish["side_options"] as? [String] == ["potato"])
        #expect(dish["side_kind"] is NSNull)
        #expect(side["side_kind"] as? String == "potato")
        #expect(side["side_options"] as? [String] == [])
        #expect(MealPlanEndpoints.addSide(recipeID: 2, to: 10).path == "meal-plan/10/sides")
        #expect(RecipeEndpoints.sides(of: 1).path == "recipes/1/sides")
    }
}
