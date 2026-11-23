import Foundation

/// Why a meal goes with the rest of the plan; the server computes it, the app puts it into words.
public enum PlanReason: Decodable, Hashable, Sendable {
    /// A meal of the plan another one shares products with.
    public struct Partner: Decodable, Hashable, Sendable {
        public let title: String
        public let date: DayDate
    }

    /// The meal draws from the same products as `partners`, the most perishable first.
    case shares(products: [String], partners: [Partner])
    /// It uses what the pantry holds, what expires first first.
    case pantry(products: [String])
    /// The user marked the recipe as favorite.
    case favorite
    /// The household rates it well; the average from 0 to 10.
    case rating(Double)
    /// It was last planned that many days before the period.
    case lastPlanned(days: Int)
    /// It was not planned within the planner's memory.
    case notRecent
    /// A quick recipe on a weekday; `nil` minutes for recipes tagged as quick.
    case quick(minutes: Int?)
    /// A reason this version of the app does not know yet.
    case unknown

    private enum CodingKeys: String, CodingKey {
        case type, products, with, value, days, minutes
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(String.self, forKey: .type) {
        case "shares":
            self = .shares(products: try container.decode([String].self, forKey: .products), partners: try container.decode([Partner].self, forKey: .with))
        case "pantry":
            self = .pantry(products: try container.decode([String].self, forKey: .products))
        case "favorite":
            self = .favorite
        case "rating":
            self = .rating(try container.decode(Double.self, forKey: .value))
        case "last_planned":
            self = .lastPlanned(days: try container.decode(Int.self, forKey: .days))
        case "not_recent":
            self = .notRecent
        case "quick":
            self = .quick(minutes: try container.decodeIfPresent(Int.self, forKey: .minutes))
        default:
            self = .unknown
        }
    }
}

/// The reasons of one saved entry, as `GET /meal-plan/reasons` lists them.
public struct MealPlanEntryReasons: Decodable, Sendable {
    public let entryID: Int
    public let reasons: [PlanReason]

    private enum CodingKeys: String, CodingKey {
        case reasons
        case entryID = "entryId"
    }
}
