import Foundation

/// Writes to the meal plan and the pantry, applied to the local copy.
extension Replica {
    /// Answers a write to the meal plan; `nil` for other calls.
    mutating func writePlan(_ request: LocalRequest, now: Date) throws -> LocalResult? {
        if request.matches(.post, "meal-plan") {
            let entry = try planEntry(from: request.body)
            put(.mealPlanEntries, entry)
            return LocalResult(body: resource(shownEntry(entry)), areas: [.plan], change: QueuedChange(created: [entry.recordID ?? 0], createdKind: .mealPlanEntries))
        }
        if request.matches(.post, "meal-plan", "batch") {
            let entries = try (request.body["entries"] as? [JSONObject] ?? []).map { try planEntry(from: $0) }
            entries.forEach { put(.mealPlanEntries, $0) }
            return LocalResult(body: resource(entries.map(shownEntry)), areas: [.plan], change: QueuedChange(created: entries.compactMap(\.recordID), createdKind: .mealPlanEntries))
        }
        if request.matches(.patch, "meal-plan", "*") {
            var entry = try existing(.mealPlanEntries, request.id(at: 1))
            for field in ["date", "meal", "servings"] {
                if let value = request.body[field] {
                    entry[field] = value
                }
            }
            if let cooked = request.body["cooked"] as? Bool {
                entry["cooked_at"] = cooked ? JSONValue.timestamp(now) : NSNull()
            }
            if let recipeID = request.body["recipe_id"] as? Int {
                entry["recipe"] = try existing(.recipes, recipeID)
            }
            put(.mealPlanEntries, entry)
            return LocalResult(body: resource(shownEntry(entry)), areas: [.plan], change: QueuedChange())
        }
        if request.matches(.delete, "meal-plan", "*") {
            let id = try existing(.mealPlanEntries, request.id(at: 1)).recordID ?? 0
            remove(.mealPlanEntries, id)
            return LocalResult(areas: [.plan], change: QueuedChange())
        }
        return nil
    }

    private mutating func planEntry(from body: JSONObject) throws -> JSONObject {
        [
            "id": makeTemporaryID(),
            "date": body["date"] ?? "",
            "meal": body["meal"] ?? "",
            "servings": body["servings"] ?? 1,
            "cooked_at": NSNull(),
            "recipe": try existing(.recipes, body["recipe_id"] as? Int),
        ]
    }

    /// Answers a write to the pantry; `nil` for other calls.
    mutating func writePantry(_ request: LocalRequest, now: Date) throws -> LocalResult? {
        if request.matches(.post, "pantry") {
            let product = try existing(.products, request.body["product_id"] as? Int)
            let item: JSONObject = [
                "id": makeTemporaryID(),
                "amount": request.body["amount"] ?? 0,
                "opened_on": request.body["opened_on"] ?? NSNull(),
                "expires_on": request.body["expires_on"] ?? expiry(of: product, openedOn: request.body["opened_on"] as? String, now: now),
                "product": product,
            ]
            put(.pantryItems, item)
            return LocalResult(body: resource(shownPantryItem(item)), areas: [.pantry], change: QueuedChange(created: [item.recordID ?? 0], createdKind: .pantryItems))
        }
        if request.matches(.patch, "pantry", "*") {
            var item = try existing(.pantryItems, request.id(at: 1))
            for field in ["amount", "opened_on", "expires_on"] {
                if let value = request.body[field] {
                    item[field] = value
                }
            }
            put(.pantryItems, item)
            return LocalResult(body: resource(shownPantryItem(item)), areas: [.pantry], change: QueuedChange())
        }
        if request.matches(.delete, "pantry", "*") {
            let id = try existing(.pantryItems, request.id(at: 1)).recordID ?? 0
            remove(.pantryItems, id)
            return LocalResult(areas: [.pantry], change: QueuedChange())
        }
        return nil
    }

    /// The day an opened package expires by the shelf life of its product; `null` for products that keep.
    private func expiry(of product: JSONObject, openedOn: String?, now: Date) -> Any {
        guard let days = product["shelf_life_opened_days"] as? Int else {
            return NSNull()
        }
        let opened = openedOn.flatMap { DayDate($0) } ?? DayDate(now)
        return opened.adding(days: days).description
    }
}
