import Foundation

/// Handling of the server address the user enters during setup.
public enum ServerAddress {
    private static let apiPath = "api/v1"

    /// Turns user input into the root URL of a server.
    ///
    /// A missing scheme defaults to HTTPS; a trailing slash or API path is removed.
    /// Returns `nil` when the input is not an HTTP or HTTPS address.
    public static func normalize(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard var components = URLComponents(string: text),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty
        else {
            return nil
        }
        components.scheme = scheme
        components.query = nil
        components.fragment = nil
        var path = components.path
        while path.hasSuffix("/") {
            path.removeLast()
        }
        if path.hasSuffix("/\(apiPath)") {
            path.removeLast(apiPath.count + 1)
        }
        components.path = path
        return components.url
    }

    /// Base URL of the API of the server at `serverURL`.
    public static func apiBaseURL(for serverURL: URL) -> URL {
        serverURL.appending(path: apiPath)
    }
}
