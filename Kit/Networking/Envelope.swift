/// The `{"data": ...}` wrapper around resources.
struct DataEnvelope<Payload: Decodable>: Decodable {
    let data: Payload
}

/// One page of a paginated list.
public struct Page<Element: Decodable & Sendable>: Decodable, Sendable {
    /// Elements of this page.
    public let items: [Element]
    /// Number of this page, starting at 1.
    public let currentPage: Int
    /// Number of the last page.
    public let lastPage: Int
    /// Number of elements across all pages.
    public let total: Int

    /// Whether further pages follow.
    public var hasMore: Bool {
        currentPage < lastPage
    }

    private enum CodingKeys: String, CodingKey {
        case data, meta
    }

    private enum MetaKeys: String, CodingKey {
        case currentPage, lastPage, total
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let meta = try container.nestedContainer(keyedBy: MetaKeys.self, forKey: .meta)
        items = try container.decode([Element].self, forKey: .data)
        currentPage = try meta.decode(Int.self, forKey: .currentPage)
        lastPage = try meta.decode(Int.self, forKey: .lastPage)
        total = try meta.decode(Int.self, forKey: .total)
    }
}
