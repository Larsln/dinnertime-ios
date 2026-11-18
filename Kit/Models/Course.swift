/// The main category of a dish, such as starter or main course; a recipe has at most one.
public struct Course: Decodable, Hashable, Identifiable, Sendable {
    /// Language-neutral key the API filters and stores by.
    public let key: String
    /// Name in the requested language.
    public let name: String

    public var id: String {
        key
    }
}
