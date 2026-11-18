import Foundation

/// A link that waits to be imported, with the number of dishes the user said it shows.
public struct PendingLink: Codable, Hashable, Sendable {
    public let url: URL
    /// Number of dishes in the video; `nil` lets the server find out.
    public let dishCount: Int?

    public init(url: URL, dishCount: Int? = nil) {
        self.url = url
        self.dishCount = dishCount
    }

    private enum CodingKeys: String, CodingKey {
        case url, dishCount
    }

    /// Reads an entry; lists written before the number of dishes existed hold bare addresses.
    public init(from decoder: any Decoder) throws {
        if let address = try? decoder.singleValueContainer().decode(String.self) {
            guard let url = URL(string: address) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid link: \(address)"))
            }
            self.init(url: url)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(url: try container.decode(URL.self, forKey: .url), dishCount: try container.decodeIfPresent(Int.self, forKey: .dishCount))
    }
}
