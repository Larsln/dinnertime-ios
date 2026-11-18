import Foundation

/// Where a product can be bought: a shop with the size and the price of the package it sells.
public struct ProductOffer: Decodable, Hashable, Identifiable, Sendable {
    /// Longest name of a shop the server stores.
    public static let storeLimit = 100

    public let id: Int
    /// Id of the shop in the list of shops; `nil` for offers stored before shops were a list.
    public let storeID: Int?
    /// Name of the shop.
    public let store: String
    /// Whether the household buys at the shop at the moment.
    ///
    /// The server does not send this; the local copy states it from its list of shops.
    public let isStoreActive: Bool
    /// Size of the package in the base unit of the product; `nil` when it is not known.
    public let amountInBase: Double?
    /// Price of the package in the currency of the household; `nil` when it is not known.
    public let price: Double?

    private enum CodingKeys: String, CodingKey {
        case id, store, amountInBase, price
        case storeID = "storeId"
        case isStoreActive = "storeIsActive"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        storeID = try container.decodeIfPresent(Int.self, forKey: .storeID)
        store = try container.decode(String.self, forKey: .store)
        isStoreActive = try container.decodeIfPresent(Bool.self, forKey: .isStoreActive) ?? true
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

extension Sequence where Element == ProductOffer {
    /// The offers with those of paused shops after the others; the order is kept otherwise.
    public var activeFirst: [ProductOffer] {
        filter(\.isStoreActive) + filter { !$0.isStoreActive }
    }

    /// Whether there are offers and every one of them is at a paused shop.
    public var areAllPaused: Bool {
        contains { _ in true } && allSatisfy { !$0.isStoreActive }
    }
}

extension Product {
    /// Whether the household stated something about buying the product: a note or a shop it buys at.
    public var hasBuyingHints: Bool {
        note != nil || offers.contains(where: \.isStoreActive)
    }
}
