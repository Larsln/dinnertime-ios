import Foundation

/// Writes to products, their values, tools and the household settings, applied to the local copy.
///
/// The offers of a product are written in `ReplicaOffers.swift`.
extension Replica {
    /// Answers a write to a product or one of its values; `nil` for other calls, among them merging, which needs the server.
    mutating func writeProduct(_ request: LocalRequest) throws -> LocalResult? {
        if request.matches(.post, "products") {
            let name = request.body["name"] as? String ?? ""
            guard !all(.products).contains(where: { ($0["name"] as? String)?.caseInsensitiveCompare(name) == .orderedSame }) else {
                throw APIError.validation(message: String(localized: "A product with this name exists already.", bundle: .kit), fields: [:])
            }
            let product: JSONObject = [
                "id": makeTemporaryID(), "name": name, "plural_name": NSNull(), "icon": NSNull(), "base_unit": "g",
                "is_pantry_staple": false, "shelf_life_opened_days": NSNull(), "note": NSNull(), "status": "confirmed", "enriched_at": NSNull(),
                "store_section": NSNull(), "aliases": [String](), "conversions": [JSONObject](), "packages": [JSONObject](),
                "offers": [JSONObject](),
            ]
            put(.products, product)
            return LocalResult(body: resource(shownProduct(product)), areas: [.products], change: QueuedChange(created: [product.recordID ?? 0], createdKind: .products))
        }
        if request.matches(.patch, "product-packages", "*") || request.matches(.delete, "product-packages", "*") {
            return try writePackage(request)
        }
        guard request.path.first == "products", let id = request.id(at: 1) else {
            return nil
        }
        var product = try existing(.products, id)
        var created: [Int] = []
        if request.matches(.delete, "products", "*") {
            guard shownProduct(product)["recipe_count"] as? Int == 0 else {
                throw failure(409, String(localized: "The product is used by a recipe and cannot be deleted.", bundle: .kit))
            }
            remove(.products, id)
            return LocalResult(areas: [.products], change: QueuedChange())
        } else if request.matches(.patch, "products", "*") {
            for field in ["name", "plural_name", "icon", "base_unit", "is_pantry_staple", "shelf_life_opened_days", "note"] {
                if let value = request.body[field] {
                    product[field] = value
                }
            }
            if let section = request.body["store_section_id"] {
                product["store_section"] = (section as? Int).flatMap { record(.storeSections, $0) } ?? NSNull()
            }
        } else if request.matches(.post, "products", "*", "confirm") {
            product["status"] = "confirmed"
            for list in ["conversions", "packages"] {
                product[list] = (product[list] as? [JSONObject] ?? []).map { $0.merging(["status": "confirmed"]) { _, new in new } }
            }
        } else if request.matches(.post, "products", "*", "packages") {
            let package: JSONObject = [
                "id": makeTemporaryID(), "label": request.body["label"] ?? "", "amount_in_base": request.body["amount_in_base"] ?? 0,
                "status": "confirmed", "source": "user",
            ]
            product["packages"] = (product["packages"] as? [JSONObject] ?? []) + [package]
            created = [package.recordID ?? 0]
        } else if request.matches(.put, "products", "*", "conversions", "*") || request.matches(.delete, "products", "*", "conversions", "*") {
            let unit = try existing(.units, request.id(at: 3))
            var conversions = (product["conversions"] as? [JSONObject] ?? []).filter { ($0["unit"] as? JSONObject)?.recordID != unit.recordID }
            if request.method == .put {
                conversions.append(["id": makeTemporaryID(), "unit": unit, "amount_in_base": request.body["amount_in_base"] ?? NSNull(), "status": "confirmed", "source": "user"])
            }
            product["conversions"] = conversions
        } else {
            return nil
        }
        put(.products, product)
        return LocalResult(body: resource(shownProduct(product)), areas: [.products, .shopping, .pantry, .recipes], change: QueuedChange(created: created))
    }

    private mutating func writePackage(_ request: LocalRequest) throws -> LocalResult? {
        let id = request.id(at: 1)
        guard var product = all(.products).first(where: { ($0["packages"] as? [JSONObject] ?? []).contains { $0.recordID == id } }) else {
            throw failure(404)
        }
        var packages = product["packages"] as? [JSONObject] ?? []
        var answer: Any?
        if let index = packages.firstIndex(where: { $0.recordID == id }) {
            if request.method == .delete {
                packages.remove(at: index)
            } else {
                packages[index].merge(request.body.filter { ["label", "amount_in_base"].contains($0.key) }) { _, new in new }
                packages[index]["status"] = "confirmed"
                answer = resource(packages[index])
            }
        }
        product["packages"] = packages
        put(.products, product)
        return LocalResult(body: answer, areas: [.products, .shopping], change: QueuedChange())
    }

    /// Answers a write to a tool; `nil` for other calls, among them merging, which needs the server.
    mutating func writeTool(_ request: LocalRequest) throws -> LocalResult? {
        if request.matches(.post, "tools") {
            let tool: JSONObject = ["id": makeTemporaryID(), "name": request.body["name"] ?? "", "is_owned": request.body["is_owned"] as? Bool ?? true]
            put(.tools, tool)
            return LocalResult(body: resource(shownTool(tool)), areas: [.tools], change: QueuedChange(created: [tool.recordID ?? 0], createdKind: .tools))
        }
        if request.matches(.patch, "tools", "*") {
            var tool = try existing(.tools, request.id(at: 1))
            tool.merge(request.body.filter { ["name", "is_owned"].contains($0.key) }) { _, new in new }
            put(.tools, tool)
            return LocalResult(body: resource(shownTool(tool)), areas: [.tools, .recipes], change: QueuedChange())
        }
        if request.matches(.delete, "tools", "*") {
            let tool = try existing(.tools, request.id(at: 1))
            guard shownTool(tool)["recipe_count"] as? Int == 0 else {
                throw failure(409, String(localized: "The tool is needed by a recipe and cannot be deleted.", bundle: .kit))
            }
            remove(.tools, tool.recordID ?? 0)
            return LocalResult(areas: [.tools], change: QueuedChange())
        }
        return nil
    }

    /// Answers a change of the household settings; `nil` for other calls.
    mutating func writeSettings(_ request: LocalRequest) -> LocalResult? {
        guard request.matches(.patch, "settings", "household") else {
            return nil
        }
        household.merge(request.body) { _, new in new }
        return LocalResult(body: resource(household), areas: [], change: QueuedChange())
    }

    /// Applies a write to the copy and answers the way the server would; `nil` for calls that need the server.
    ///
    /// `key` is the idempotency key under which the change is sent later and `now` the time the user acted.
    mutating func write(_ request: LocalRequest, key: String, now: Date) throws -> LocalResult? {
        guard request.method != .get else {
            return nil
        }
        let repairs = repairs(for: request)
        var result = try writeRecipe(request, key: key)
        result = try result ?? writePlan(request, now: now)
        result = try result ?? writePantry(request, now: now)
        result = try result ?? writeShopping(request, key: key, now: now)
        result = try result ?? writeOffer(request)
        result = try result ?? writeProduct(request)
        result = try result ?? writeTool(request)
        result = result ?? writeSettings(request)
        result?.change?.repairs = repairs
        return result
    }
}
