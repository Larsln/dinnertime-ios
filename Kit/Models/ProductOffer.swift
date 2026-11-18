import Foundation

/// Where a product can be bought: a shop with the size and the price of the package it sells.
public struct ProductOffer: Decodable, Hashable, Identifiable, Sendable {
    /// Longest name of a shop the server stores.
    public static let storeLimit = 100

    public let id: Int
    /// Name of the shop.
    public let store: String
    /// Size of the package in the base unit of the product; `nil` when it is not known.
    public let amountInBase: Double?
    /// Price of the package in the currency of the household; `nil` when it is not known.
    public let price: Double?

    private enum CodingKeys: String, CodingKey {
        case id, store, amountInBase, price
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        store = try container.decode(String.self, forKey: .store)
        amountInBase = Self.number(in: container, forKey: .amountInBase)
        price = Self.number(in: container, forKey: .price)
    }

    /// The name of a shop as it is stored: without surrounding space, cut to the limit, `nil` when nothing remains.
    public static func storedStore(_ text: String?) -> String? {
        let text = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(storeLimit)
        return text.isEmpty ? nil : String(text)
    }

    /// Reads a number the server may write as a number or as a decimal text such as "2.59".
    private static func number(in container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Double? {
        if let number = try? container.decodeIfPresent(Double.self, forKey: key) {
            return number
        }
        return (try? container.decodeIfPresent(String.self, forKey: key)).flatMap(Double.init)
    }
}

extension Product {
    /// Whether the household stated something about buying the product: a note or a shop.
    public var hasBuyingHints: Bool {
        note != nil || !offers.isEmpty
    }
}
