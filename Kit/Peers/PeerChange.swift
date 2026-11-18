import Foundation

/// A change to the shopping list as devices of one household exchange it without the server.
///
/// It carries the idempotency key and the time of the original action, so that every device
/// queues it under the same key and the server runs it only once, whoever delivers it first.
public struct PeerChange: Codable, Equatable, Sendable {
    /// What was done to the item.
    public enum Action: Codable, Equatable, Sendable {
        /// The item was checked off or brought back.
        case check(Bool)
        /// A manual item with this label was added to the list.
        case add(label: String, listID: Int)
        /// The manual item was deleted.
        case delete
    }

    /// Names an item across devices.
    ///
    /// Items the server knows are named by its id. Items created offline are named by the key
    /// of the request that created them, because every device gives them another temporary id.
    public struct Item: Codable, Equatable, Sendable {
        public let serverID: Int?
        public let creationKey: String?

        public init(serverID: Int?, creationKey: String?) {
            self.serverID = serverID
            self.creationKey = creationKey
        }
    }

    /// Idempotency key of the original request.
    public let key: String
    /// When the user acted.
    public let clientTime: Date
    public let item: Item
    public let action: Action

    public init(key: String, clientTime: Date, item: Item, action: Action) {
        self.key = key
        self.clientTime = clientTime
        self.item = item
        self.action = action
    }
}
