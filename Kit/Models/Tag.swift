/// A label attached to recipes.
public struct Tag: Decodable, Hashable, Identifiable, Sendable {
    /// Group a tag belongs to.
    public enum Kind: String, Decodable, Sendable {
        case meal, category, tag
    }

    public let id: Int
    public let type: Kind
    /// Language-neutral key of built-in tags.
    public let key: String?
    /// Name in the requested language.
    public let name: String
}
