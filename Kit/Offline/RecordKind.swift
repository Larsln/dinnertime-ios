import Foundation

/// The kinds of records the server reports changes of, named as in the sync feed.
public enum RecordKind: String, CaseIterable, Codable, Sendable {
    case units
    case storeSections = "store_sections"
    case tags
    case tools
    case stores
    case products
    case recipes
    case mealPlanEntries = "meal_plan_entries"
    case pantryItems = "pantry_items"
    case shoppingLists = "shopping_lists"

    /// The part of the app that shows records of this kind.
    public var area: RealtimeArea {
        switch self {
        case .units, .storeSections, .stores, .products: .products
        case .tags, .recipes: .recipes
        case .tools: .tools
        case .mealPlanEntries: .plan
        case .pantryItems: .pantry
        case .shoppingLists: .shopping
        }
    }
}

/// A JSON object as the server sends it; records are kept in this form and decoded where they are shown.
typealias JSONObject = [String: Any]

extension Dictionary where Key == String, Value == Any {
    /// The `id` of a record.
    var recordID: Int? {
        self["id"] as? Int
    }

    /// A value that is present and not `null`.
    func value<T>(_ key: String, as type: T.Type = T.self) -> T? {
        self[key] as? T
    }
}

/// Reading and writing of JSON values that are not known at compile time.
enum JSONValue {
    /// Parses a JSON object.
    static func object(from data: Data) throws -> JSONObject {
        guard let object = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw APIError.invalidResponse
        }
        return object
    }

    /// Serializes a JSON value with stable key order.
    static func data(_ value: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .fragmentsAllowed])
    }

    /// A timestamp as the server writes it.
    static func timestamp(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    /// Replaces every integer equal to `old` by `new`, anywhere in a JSON value.
    ///
    /// Temporary ids are negative and unique across all kinds, so no other number can be hit.
    static func replacing(_ old: Int, with new: Int, in value: Any) -> Any {
        if let object = value as? JSONObject {
            return object.mapValues { replacing(old, with: new, in: $0) }
        }
        if let array = value as? [Any] {
            return array.map { replacing(old, with: new, in: $0) }
        }
        if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue == Double(old) {
            return new
        }
        return value
    }
}
