import Foundation

/// Maps HTTP answers to their body or to an ``APIError``.
enum ResponseInterpreter {
    /// Body of error answers: `{"message": "...", "errors": {"field": ["..."]}}`.
    private struct ErrorBody: Decodable {
        let message: String?
        let errors: [String: [String]]?
    }

    /// Returns the body of a successful answer and throws for every other status.
    static func body(of data: Data, response: URLResponse) throws -> Data {
        guard let response = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        if (200..<300).contains(response.statusCode) {
            return data
        }
        if response.statusCode == 401 {
            throw APIError.unauthorized
        }
        let body = try? JSONCoding.makeDecoder().decode(ErrorBody.self, from: data)
        let message = body?.message.flatMap { $0.isEmpty ? nil : $0 }
        if response.statusCode == 422, let message {
            throw APIError.validation(message: message, fields: body?.errors ?? [:])
        }
        throw APIError.server(status: response.statusCode, message: message)
    }
}
