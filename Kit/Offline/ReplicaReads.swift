import Foundation

/// Records as the screens show them: embedded records are replaced by the copy's own and counts are made locally.
extension Replica {
    /// The copy's own version of an embedded record, or the snapshot if the copy has none.
    func current(_ kind: RecordKind, _ snapshot: Any?) -> Any {
        guard let snapshot = snapshot as? JSONObject, let id = snapshot.recordID else {
            return snapshot ?? NSNull()
        }
        return record(kind, id) ?? snapshot
    }

    /// A product with its store section and the shops of its offers as stored now and the number of ingredient lines that use it.
    func shownProduct(_ product: JSONObject) -> JSONObject {
        var product = product
        if let offers = product["offers"] as? [JSONObject] {
            product["offers"] = offers.map(shownOffer)
        }
        product["store_section"] = current(.storeSections, product["store_section"])
        product["recipe_count"] = all(.recipes).reduce(0) { count, recipe in
            count + (recipe["ingredients"] as? [JSONObject] ?? []).filter { ($0["product"] as? JSONObject)?.recordID == product.recordID }.count
        }
        return product
    }

    /// A tool with the number of recipes that need it.
    func shownTool(_ tool: JSONObject) -> JSONObject {
        var tool = tool
        tool["recipe_count"] = all(.recipes).filter { recipe in
            (recipe["tools"] as? [JSONObject] ?? []).contains { $0.recordID == tool.recordID }
        }.count
        return tool
    }

    /// A recipe with its tags, tools, products and units as stored now.
    func shownRecipe(_ recipe: JSONObject) -> JSONObject {
        var recipe = recipe
        recipe["tags"] = (recipe["tags"] as? [Any] ?? []).map { current(.tags, $0) }
        recipe["tools"] = (recipe["tools"] as? [Any] ?? []).map { current(.tools, $0) }
        recipe["ingredients"] = (recipe["ingredients"] as? [JSONObject] ?? []).map { line in
            var line = line
            line["product"] = current(.products, line["product"])
            line["unit"] = current(.units, line["unit"])
            return line
        }
        return recipe
    }

    /// A plan entry with its recipe as stored now.
    func shownEntry(_ entry: JSONObject) -> JSONObject {
        var entry = entry
        if let recipe = current(.recipes, entry["recipe"]) as? JSONObject {
            entry["recipe"] = shownRecipe(recipe)
        }
        return entry
    }

    /// A pantry item with its product as stored now.
    func shownPantryItem(_ item: JSONObject) -> JSONObject {
        var item = item
        if let product = current(.products, item["product"]) as? JSONObject {
            item["product"] = shownProduct(product)
        }
        return item
    }

    /// A shopping list whose items carry their products as stored now.
    func shownList(_ list: JSONObject) -> JSONObject {
        var list = list
        list["items"] = (list["items"] as? [JSONObject] ?? []).map(shownItem)
        return list
    }

    /// The shopping list of the latest period.
    var currentShoppingList: JSONObject? {
        all(.shoppingLists).max { ($0["starts_on"] as? String ?? "") < ($1["starts_on"] as? String ?? "") }
    }

    /// Products whose name or alias contains `search`, sorted by name.
    func products(search: String?) -> [JSONObject] {
        let found = all(.products).filter { product in
            matches(product["name"] as? String, search)
                || (product["aliases"] as? [String] ?? []).contains { matches($0, search) }
        }
        return sorted(found, by: "name").map(shownProduct)
    }

    /// Products with details or conversions that still carry a suggested value, sorted by name.
    var productsAwaitingReview: [JSONObject] {
        let isSuggested: (JSONObject) -> Bool = { $0["status"] as? String == "suggested" }
        let found = all(.products).filter { product in
            isSuggested(product)
                || (product["conversions"] as? [JSONObject] ?? []).contains(where: isSuggested)
        }
        return sorted(found, by: "name").map(shownProduct)
    }

    /// Answers a read from the copy; `nil` for calls that are no reads of data the copy holds.
    func read(_ request: LocalRequest) throws -> Any? {
        let query = request.query
        if request.matches(.get, "recipes") {
            let filter = RecipeFilter(
                search: query["search"],
                tagIDs: (request.lists["tags"] ?? []).compactMap(Int.init),
                courses: request.lists["courses"] ?? [],
                favoritesOnly: query["favorite"] == "1"
            )
            return page(recipes(matching: filter))
        }
        if request.matches(.get, "recipes", "*") {
            return resource(shownRecipe(try existing(.recipes, request.id(at: 1))))
        }
        if request.matches(.get, "recipes", "*", "sides") {
            return resource(try sideOptions(forRecipe: request.id(at: 1)))
        }
        if request.matches(.get, "products") {
            return page(products(search: query["search"]))
        }
        if request.matches(.get, "products", "*") {
            return resource(shownProduct(try existing(.products, request.id(at: 1))))
        }
        if request.matches(.get, "review") {
            return page(productsAwaitingReview)
        }
        if request.matches(.get, "tools") {
            return resource(sorted(all(.tools).filter { matches($0["name"] as? String, query["search"]) }, by: "name").map(shownTool))
        }
        if request.matches(.get, "units") {
            return resource(all(.units).sorted { ($0.recordID ?? 0) < ($1.recordID ?? 0) })
        }
        if request.matches(.get, "tags") {
            return resource(all(.tags).sorted { ($0.recordID ?? 0) < ($1.recordID ?? 0) })
        }
        if request.matches(.get, "store-sections") {
            return resource(all(.storeSections).sorted { ($0["position"] as? Int ?? 0) < ($1["position"] as? Int ?? 0) })
        }
        if request.matches(.get, "meal-plan") {
            let from = query["from"] ?? ""
            let to = query["to"] ?? "9999"
            let entries = all(.mealPlanEntries).filter { ($0["date"] as? String ?? "") >= from && ($0["date"] as? String ?? "") <= to }
            return resource(entries.sorted { ($0["date"] as? String ?? "", $0.recordID ?? 0) < ($1["date"] as? String ?? "", $1.recordID ?? 0) }.map(shownEntry))
        }
        if request.matches(.get, "pantry") {
            let items = all(.pantryItems).sorted { ($0["expires_on"] as? String ?? "9999", $0.recordID ?? 0) < ($1["expires_on"] as? String ?? "9999", $1.recordID ?? 0) }
            return resource(items.map(shownPantryItem))
        }
        if request.matches(.get, "shopping-lists", "current") {
            guard let list = currentShoppingList else {
                throw failure(404)
            }
            return resource(shownList(list))
        }
        if request.matches(.get, "shopping-lists", "*") {
            return resource(shownList(try existing(.shoppingLists, request.id(at: 1))))
        }
        if request.matches(.get, "stores") {
            return resource(sorted(all(.stores), by: "name").map(shownStore))
        }
        if request.matches(.get, "settings", "household") {
            return resource(household)
        }
        return nil
    }

    /// The record with `id`, or the failure the server answers for a missing one.
    func existing(_ kind: RecordKind, _ id: Int?) throws -> JSONObject {
        guard let id, let record = record(kind, id) else {
            throw failure(404)
        }
        return record
    }
}
