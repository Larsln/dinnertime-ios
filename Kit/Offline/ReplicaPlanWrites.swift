import Foundation

/// Writes to the meal plan, the pantry and the shopping list, applied to the local copy.
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

    /// Answers a write to a shopping list; `nil` for other calls, among them creating a list, which needs the server.
    mutating func writeShopping(_ request: LocalRequest, key: String, now: Date) throws -> LocalResult? {
        if request.matches(.post, "shopping-lists", "*", "items") {
            var list = try existing(.shoppingLists, request.id(at: 1))
            let item = manualItem(label: request.body["label"] as? String ?? "", creationKey: key)
            list["items"] = (list["items"] as? [JSONObject] ?? []) + [item]
            put(.shoppingLists, list)
            itemActionTimes[item.recordID ?? 0] = now
            itemIDsByCreationKey[key] = item.recordID
            return LocalResult(body: resource(item), areas: [.shopping], change: QueuedChange(created: [item.recordID ?? 0], shoppingItem: item.recordID))
        }
        if request.matches(.post, "shopping-lists", "*", "stock-leftovers") {
            var list = try existing(.shoppingLists, request.id(at: 1))
            guard list["leftovers_stocked_at"] is NSNull || list["leftovers_stocked_at"] == nil else {
                throw failure(409)
            }
            list["leftovers_stocked_at"] = JSONValue.timestamp(now)
            put(.shoppingLists, list)
            return LocalResult(body: resource(shownList(list)), areas: [.shopping], change: QueuedChange())
        }
        guard request.path.first == "shopping-list-items", let id = request.id(at: 1), var list = listHolding(item: id) else {
            return request.path.first == "shopping-list-items" ? try missing() : nil
        }
        var items = list["items"] as? [JSONObject] ?? []
        guard let index = items.firstIndex(where: { $0.recordID == id }) else {
            return try missing()
        }
        var answer: Any?
        if request.matches(.patch, "shopping-list-items", "*") {
            if let checked = request.body["checked"] as? Bool {
                items[index]["checked_at"] = checked ? JSONValue.timestamp(now) : NSNull()
            }
            if let label = request.body["label"] {
                items[index]["label"] = label
            }
            answer = resource(items[index])
        } else if request.matches(.delete, "shopping-list-items", "*") {
            items.remove(at: index)
        } else {
            return nil
        }
        list["items"] = items
        put(.shoppingLists, list)
        itemActionTimes[id] = now
        return LocalResult(body: answer, areas: [.shopping], change: QueuedChange(shoppingItem: id))
    }

    /// The shopping list that holds the item with `id`.
    func listHolding(item id: Int) -> JSONObject? {
        all(.shoppingLists).first { ($0["items"] as? [JSONObject] ?? []).contains { $0.recordID == id } }
    }

    /// The item with `id` of any shopping list.
    func shoppingItem(_ id: Int) -> JSONObject? {
        listHolding(item: id).flatMap { ($0["items"] as? [JSONObject] ?? []).first { $0.recordID == id } }
    }

    /// A manual item as the server would create it; it remembers the key of its creation so that other devices can name it.
    mutating func manualItem(label: String, creationKey: String) -> JSONObject {
        [
            "id": makeTemporaryID(), "label": label, "is_manual": true, "needed_amount": NSNull(), "purchase_amount": NSNull(),
            "packages": [JSONObject](), "leftover_amount": 0, "wasted_amount": 0, "uses": [JSONObject](), "is_approximate": false,
            "extra_amounts": [JSONObject](), "checked_at": NSNull(), "product": NSNull(), "creation_key": creationKey,
        ]
    }

    private func missing() throws -> LocalResult? {
        throw failure(404)
    }
}
