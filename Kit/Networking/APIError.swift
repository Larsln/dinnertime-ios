import Foundation

/// Failures of an API call.
public enum APIError: Error, Equatable, Sendable {
    /// The token is missing, expired or revoked.
    case unauthorized
    /// The server rejected the input; `fields` maps field names to their messages.
    case validation(message: String, fields: [String: [String]])
    /// The server answered with another error status.
    case server(status: Int, message: String?)
    /// No answer arrived.
    case unreachable
    /// The answer could not be understood.
    case invalidResponse
}

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            String(localized: "Your session has expired. Please sign in again.", bundle: .kit)
        case let .validation(message, fields):
            Self.validationText(message: message, fields: fields)
        case let .server(status, message):
            message ?? String(localized: "The server answered with an error (\(status)).", bundle: .kit)
        case .unreachable:
            String(localized: "The server could not be reached.", bundle: .kit)
        case .invalidResponse:
            String(localized: "The server sent an unexpected answer.", bundle: .kit)
        }
    }

    private static func validationText(message: String, fields: [String: [String]]) -> String {
        let details = fields.keys.sorted().flatMap { fields[$0] ?? [] }
        return details.isEmpty ? message : details.joined(separator: "\n")
    }
}
