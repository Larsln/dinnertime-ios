/// A shop of the household where products are bought.
public struct Store: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public var name: String
    /// Whether the household buys there at the moment; a shop that is closed for a while is paused.
    public var isActive: Bool
    /// Number of offers noted for the shop.
    public let offerCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, isActive, offerCount
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        offerCount = try container.decodeIfPresent(Int.self, forKey: .offerCount)
    }
}

extension Sequence where Element == Store {
    /// The shops to choose from when an offer is entered: the active ones, most used first and equally used ones by name.
    public var choices: [Store] {
        filter(\.isActive).sorted { first, second in
            let (firstUses, secondUses) = (first.offerCount ?? 0, second.offerCount ?? 0)
            return firstUses == secondUses ? first.name.localizedStandardCompare(second.name) == .orderedAscending : firstUses > secondUses
        }
    }

    /// The shop called `name`, ignoring case and surrounding space.
    public func first(named name: String) -> Store? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// The shops whose name contains `search`, ignoring case; a blank search keeps all.
    public func matching(_ search: String) -> [Store] {
        let search = search.trimmingCharacters(in: .whitespaces)
        return filter { search.isEmpty || $0.name.range(of: search, options: .caseInsensitive) != nil }
    }
}
