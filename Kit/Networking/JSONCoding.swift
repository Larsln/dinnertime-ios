import Foundation

/// JSON coders configured for the conventions of the API.
///
/// Keys are snake case on the wire and camel case in Swift. Coding keys are therefore
/// written the way the key strategy sees them, for example `"recipeId"` for `recipe_id`.
enum JSONCoding {
    /// Decoder that reads snake case keys and ISO 8601 timestamps with or without fractional seconds.
    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = timestamp(from: text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid timestamp: \(text)")
            }
            return date
        }
        return decoder
    }

    /// Encoder that writes snake case keys.
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }

    private static func timestamp(from text: String) -> Date? {
        let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        let whole = Date.ISO8601FormatStyle(includingFractionalSeconds: false)
        return (try? fractional.parse(text)) ?? (try? whole.parse(text))
    }
}
