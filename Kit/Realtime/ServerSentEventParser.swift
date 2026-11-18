import Foundation

/// One event of a Server-Sent Events stream.
public struct ServerSentEvent: Equatable, Sendable {
    /// Name of the event; `nil` for the default kind, "message".
    public let name: String?
    /// The data lines of the event, joined by line feeds.
    public let data: String
}

/// Turns the bytes of a Server-Sent Events stream into events.
///
/// The parser is fed byte by byte because the events are delimited by empty lines, which
/// line-based readers tend to drop. Comment lines, which servers send as heartbeat, and
/// fields other than `event` and `data` are ignored.
public struct ServerSentEventParser: Sendable {
    private static let lineFeed = UInt8(ascii: "\n")
    private static let carriageReturn = UInt8(ascii: "\r")

    private var line: [UInt8] = []
    private var name: String?
    private var data: [String] = []
    private var endedWithCarriageReturn = false

    public init() {}

    /// Takes the next byte of the stream and answers with the event it completes, if any.
    public mutating func consume(_ byte: UInt8) -> ServerSentEvent? {
        let followsCarriageReturn = endedWithCarriageReturn
        endedWithCarriageReturn = byte == Self.carriageReturn
        if byte == Self.lineFeed, followsCarriageReturn {
            return nil
        }
        guard byte == Self.lineFeed || byte == Self.carriageReturn else {
            line.append(byte)
            return nil
        }
        defer { line = [] }
        return finish(String(decoding: line, as: UTF8.self))
    }

    /// Takes a chunk of the stream and answers with the events it completes.
    public mutating func consume(_ bytes: some Sequence<UInt8>) -> [ServerSentEvent] {
        bytes.compactMap { consume($0) }
    }

    private mutating func finish(_ line: String) -> ServerSentEvent? {
        if line.isEmpty {
            return dispatch()
        }
        guard !line.hasPrefix(":") else {
            return nil
        }
        let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let field = String(parts[0])
        let value = parts.count > 1 ? String(parts[1].hasPrefix(" ") ? parts[1].dropFirst() : parts[1]) : ""
        switch field {
        case "data": data.append(value)
        case "event": name = value
        default: break
        }
        return nil
    }

    private mutating func dispatch() -> ServerSentEvent? {
        defer {
            name = nil
            data = []
        }
        return data.isEmpty ? nil : ServerSentEvent(name: name, data: data.joined(separator: "\n"))
    }
}
