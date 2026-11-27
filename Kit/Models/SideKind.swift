/// What a side dish is based on, such as potatoes or rice; a side is of one kind and a dish names the kinds it is served with.
public struct SideKind: Decodable, Hashable, Identifiable, Sendable {
    /// Language-neutral key the API stores.
    public let key: String
    /// Name in the requested language.
    public let name: String

    public var id: String {
        key
    }
}
