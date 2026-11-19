import Foundation

/// Writes to recipes, applied to the local copy the way the server would apply them.
extension Replica {
    /// Answers a write to a recipe; `nil` for other calls.
    mutating func writeRecipe(_ request: LocalRequest, key: String) throws -> LocalResult? {
        if request.matches(.post, "recipes") {
            var recipe = emptyRecipe(id: makeTemporaryID())
            fill(&recipe, from: request.body)
            put(.recipes, recipe)
            return LocalResult(body: resource(shownRecipe(recipe)), areas: [.recipes], change: QueuedChange(created: [recipe.recordID ?? 0], createdKind: .recipes))
        }
        guard request.path.first == "recipes", let id = request.id(at: 1) else {
            return nil
        }
        if request.matches(.delete, "recipes", "*") {
            _ = try existing(.recipes, id)
            remove(.recipes, id)
            for entry in all(.mealPlanEntries) where (entry["recipe"] as? JSONObject)?.recordID == id {
                remove(.mealPlanEntries, entry.recordID ?? 0)
            }
            return LocalResult(areas: [.recipes, .plan], change: QueuedChange())
        }
        var recipe = try existing(.recipes, id)
        if request.matches(.patch, "recipes", "*") {
            fill(&recipe, from: request.body)
        } else if request.matches(.put, "recipes", "*", "rating") {
            rate(&recipe, with: (request.body["rating"] as? NSNumber)?.doubleValue)
        } else if request.matches(.put, "recipes", "*", "favorite") {
            recipe["is_favorite"] = request.body["favorite"] as? Bool ?? false
        } else if request.matches(.post, "recipes", "*", "cover") {
            recipe["cover_url"] = PendingCover.address(forKey: key)
            recipe["cover_thumb_url"] = PendingCover.address(forKey: key)
        } else {
            return nil
        }
        put(.recipes, recipe)
        return LocalResult(body: resource(shownRecipe(recipe)), areas: [.recipes, .plan], change: QueuedChange())
    }

    private func emptyRecipe(id: Int) -> JSONObject {
        [
            "id": id, "title": "", "slug": "", "description": NSNull(), "course": NSNull(), "course_name": NSNull(),
            "servings": NSNull(), "yield_text": NSNull(), "prep_minutes": NSNull(), "cook_minutes": NSNull(),
            "cover_url": NSNull(), "cover_thumb_url": NSNull(), "tags": [JSONObject](), "rating": NSNull(), "is_favorite": false,
            "average_rating": NSNull(), "rating_count": 0, "source_url": NSNull(), "source_platform": NSNull(),
            "meal_tags_locked": false, "ingredients": [JSONObject](), "steps": [JSONObject](), "tools": [JSONObject](),
        ]
    }

    /// Takes over the fields a recipe input carries; nested lists replace the stored ones as a whole.
    private mutating func fill(_ recipe: inout JSONObject, from body: JSONObject) {
        for field in ["title", "description", "servings", "yield_text", "prep_minutes", "cook_minutes", "source_url"] {
            if let value = body[field] {
                recipe[field] = value
            }
        }
        if let course = body["course"] {
            recipe["course"] = course
            recipe["course_name"] = (course as? String).map(courseName(of:)) ?? NSNull()
        }
        if let ids = body["tag_ids"] as? [Int] {
            recipe["tags"] = ids.compactMap { record(.tags, $0) }
            recipe["meal_tags_locked"] = true
        }
        if let ids = body["tool_ids"] as? [Int] {
            recipe["tools"] = ids.compactMap { record(.tools, $0) }
        }
        if let lines = body["ingredients"] as? [JSONObject] {
            recipe["ingredients"] = lines.enumerated().map { index, line in ingredient(line, position: index + 1) }
        }
        if let steps = body["steps"] as? [JSONObject] {
            recipe["steps"] = steps.enumerated().map { index, step -> JSONObject in
                ["id": makeTemporaryID(), "position": index + 1, "section": step["section"] ?? NSNull(), "text": step["text"] ?? ""]
            }
        }
    }

    private mutating func ingredient(_ line: JSONObject, position: Int) -> JSONObject {
        [
            "id": makeTemporaryID(),
            "position": position,
            "section": line["section"] ?? NSNull(),
            "quantity": line["quantity"] ?? NSNull(),
            "unit": (line["unit_id"] as? Int).flatMap { record(.units, $0) } ?? NSNull(),
            "product": (line["product_id"] as? Int).flatMap { record(.products, $0) } ?? NSNull(),
            "note": line["note"] ?? NSNull(),
            "is_estimated": line["is_estimated"] as? Bool ?? false,
            "raw_text": line["raw_text"] ?? NSNull(),
        ]
    }

    /// Name of a course as the server last listed it or as another recipe carries it; the key if neither is known.
    private func courseName(of key: String) -> String {
        let listed = ((cachedAnswers["courses"] as? JSONObject)?["data"] as? [JSONObject] ?? []).first { $0["key"] as? String == key }
        let used = all(.recipes).first { $0["course"] as? String == key }
        return listed?["name"] as? String ?? used?["course_name"] as? String ?? key
    }

    /// Sets the own rating and moves the household average and the number of ratings along with it,
    /// so the recipe reads right before the server has answered.
    private func rate(_ recipe: inout JSONObject, with rating: Double?) {
        let previous = (recipe["rating"] as? NSNumber)?.doubleValue
        var count = (recipe["rating_count"] as? NSNumber)?.intValue ?? 0
        var sum = ((recipe["average_rating"] as? NSNumber)?.doubleValue ?? 0) * Double(count)
        if let previous {
            sum -= previous
            count -= 1
        }
        if let rating {
            sum += rating
            count += 1
        }
        recipe["rating"] = rating.map { NSNumber(value: $0) } ?? NSNull()
        recipe["rating_count"] = max(count, 0)
        recipe["average_rating"] = count > 0 ? NSNumber(value: sum / Double(count)) : NSNull()
    }
}

/// The address a cover image carries while it waits to be uploaded.
public enum PendingCover {
    private static let prefix = "pending-cover/"

    /// Address of the cover that the change with `key` uploads.
    static func address(forKey key: String) -> String {
        "\(prefix)\(key).jpg"
    }

    /// Whether an address names a cover that only exists on this device.
    public static func isPending(_ url: URL) -> Bool {
        url.relativeString.hasPrefix(prefix)
    }
}
