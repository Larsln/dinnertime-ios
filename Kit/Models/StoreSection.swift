/// An area of the supermarket; positions follow the walking order.
public struct StoreSection: Decodable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let key: String?
    public let name: String
    public let position: Int
}
