import Foundation

/// One failure the app ran into.
public struct ErrorLogEntry: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    /// Where it happened, such as "PATCH products/12" or "Offline queue".
    public let context: String
    public let message: String
}

/// The last failures of the app, kept on the device so that they can be handed on when something goes wrong.
///
/// Entries name the call and what came back. They never hold the address of the server, the token or what was sent.
public final class ErrorLog: @unchecked Sendable {
    /// The log of the app.
    public static let shared = ErrorLog(file: URL.applicationSupportDirectory.appending(path: "error-log.json"))

    /// Number of entries kept; older ones make room.
    public static let limit = 500
    /// Longest message kept.
    public static let messageLimit = 600
    /// Seconds within which the same message is not noted again, for a failure that passes several places.
    private static let repeatWindow: TimeInterval = 2

    private let file: URL
    private let lock = NSLock()
    private var stored: [ErrorLogEntry]?

    public init(file: URL) {
        self.file = file
    }

    /// The entries, newest first.
    public var entries: [ErrorLogEntry] {
        lock.withLock { Array(loaded().reversed()) }
    }

    /// Notes a failure.
    public func record(_ message: String, context: String, at date: Date = .now) {
        let message = String(message.prefix(Self.messageLimit))
        lock.withLock {
            var entries = loaded()
            if let last = entries.last, last.message == message, date.timeIntervalSince(last.date) < Self.repeatWindow {
                return
            }
            entries.append(ErrorLogEntry(id: UUID(), date: date, context: context, message: message))
            write(Array(entries.suffix(Self.limit)))
        }
    }

    /// Forgets all entries.
    public func clear() {
        lock.withLock { write([]) }
    }

    /// The log as text to send along, oldest entry first, below the lines of `header`.
    public func exportText(header: [String]) -> String {
        let stamp = ISO8601DateFormatter()
        let lines = entries.reversed().map { "\(stamp.string(from: $0.date))  [\($0.context)]  \($0.message)" }
        return (header + [""] + lines).joined(separator: "\n") + "\n"
    }

    private func loaded() -> [ErrorLogEntry] {
        if let stored {
            return stored
        }
        let read = (try? Data(contentsOf: file)).flatMap { try? JSONDecoder().decode([ErrorLogEntry].self, from: $0) } ?? []
        stored = read
        return read
    }

    private func write(_ entries: [ErrorLogEntry]) {
        stored = entries
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(entries).write(to: file, options: .atomic)
    }
}

extension ErrorLog {
    /// Notes the failure of an API call by its method and path, without the query.
    ///
    /// Cancelled work, an expired session and a server that cannot be reached are part of normal use and are left out.
    public func record<Response>(_ error: any Error, of endpoint: Endpoint<Response>) {
        record(error, context: "\(endpoint.method.rawValue) \(endpoint.path)")
    }

    /// Notes a failure that happened in `context`, unless it is part of normal use.
    public func record(_ error: any Error, context: String) {
        if let detail = Self.detail(of: error) {
            record(detail, context: context)
        }
    }

    /// What to note about a failure; `nil` for those that need no entry.
    static func detail(of error: any Error) -> String? {
        switch error {
        case is CancellationError, APIError.unauthorized, APIError.unreachable:
            nil
        case let APIError.server(status, message):
            "HTTP \(status): \(message ?? "-")"
        case let APIError.validation(message, fields):
            "HTTP 422: \(message) \(fields.keys.sorted().joined(separator: ", "))"
        case let error as DecodingError:
            "Decoding: \(error)"
        default:
            String(describing: error)
        }
    }
}
