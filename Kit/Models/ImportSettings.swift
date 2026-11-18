/// How the server fetches pages and videos for imports.
public struct ImportSettings: Decodable, Equatable, Sendable {
    /// Whether web pages are fetched with the user agent of a browser.
    public var identifyAsBrowser: Bool
    /// Whether a cookie file for video platforms is stored; its content is never returned.
    public let hasCookies: Bool
}
