import Foundation

/// A package a product is sold in: its size and price, and the shop that sells it unless it is sold everywhere.
public struct ProductOffer: Decodable, Hashable, Identifiable, Sendable {
    /// Longest name of a shop the server stores.
    public static let storeLimit = 100

    public let id: Int
    /// Id of the shop in the list of shops; `nil` for a size sold everywhere.
    public let storeID: Int?
    /// Name of the shop; `nil` for a size sold everywhere.
    public let store: String?
    /// Whether the household buys at the shop at the moment.
    ///
    /// The server does not send this; the local copy states it from its list of shops.
    public let isStoreActive: Bool
    /// Size of the package as it was entered; `nil` when it is not known.
    public let amount: Double?
    /// Unit the size is stated in; `nil` without a size and for a size stored before units could be chosen.
    public private(set) var unit: OfferUnit?
    /// Price of the package in the currency of the household; `nil` when it is not known.
    public let price: Double?

    private enum CodingKeys: String, CodingKey {
        case id, store, amount, unit, amountInBase, price
        case storeID = "storeId"
        case isStoreActive = "storeIsActive"
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        storeID = try container.decodeIfPresent(Int.self, forKey: .storeID)
        store = Self.storedStore(try container.decodeIfPresent(String.self, forKey: .store))
        isStoreActive = try container.decodeIfPresent(Bool.self, forKey: .isStoreActive) ?? true
        amount = Self.number(in: container, forKey: container.contains(.amount) ? .amount : .amountInBase)
        unit = amount == nil ? nil : (try? container.decodeIfPresent(String.self, forKey: .unit)).flatMap(OfferUnit.init)
        price = Self.number(in: container, forKey: .price)
    }

    /// The offer with a size that names no unit stated in the base unit of its product.
    ///
    /// Local copies stored before units could be chosen hold such sizes.
    func stated(in baseUnit: BaseUnit) -> ProductOffer {
        guard amount != nil, unit == nil else {
            return self
        }
        var offer = self
        offer.unit = OfferUnit(baseUnit)
        return offer
    }

    /// Whether the size is sold everywhere and not at one shop.
    public var isSoldEverywhere: Bool {
        storeID == nil && store == nil
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
    /// Whether the household stated something about buying the product: a note or a package size that is not at a paused shop.
    public var hasBuyingHints: Bool {
        note != nil || offers.contains(where: \.isStoreActive)
    }
}
