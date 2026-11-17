import Foundation

/// Loads the recorded API answers that the tests decode.
enum Fixture {
    /// Contents of `Fixtures/<name>.json`.
    static func data(_ name: String) throws -> Data {
        let bundle = Bundle(for: FixtureToken.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try Data(contentsOf: url)
    }
}

/// Anchor used to locate the test bundle.
private final class FixtureToken {}
