import Foundation

/// A change the user made that still has to reach the server.
public struct OutboxEntry: Codable, Equatable, Identifiable, Sendable {
    /// The file a change uploads.
    public struct Upload: Codable, Equatable, Sendable {
        public let field: String
        public let fileName: String
        public let mimeType: String
    }

    /// Idempotency key under which the change is sent, so that a repeat is not run twice.
    public let key: String
    /// When the user acted; the server lets the later action win.
    public let clientTime: Date
    public let method: HTTPMethod
    /// Path below the API base.
    public var path: String
    /// JSON body.
    public var body: Data?
    /// Description of the file to upload; its content is kept next to the outbox under the key.
    public var upload: Upload?
    /// Temporary ids of the records the change creates, in the order of the answer.
    public var created: [Int]
    /// Kind of the created records when they are records of their own.
    public var createdKind: RecordKind?
    /// Whether the change acts on the shopping list and is shared with devices nearby.
    public var isShoppingChange: Bool
    /// What has to be read from the server again if it turns the change away.
    public var repairs: [RecordRepair]?

    public var id: String {
        key
    }

    /// The address under which the cover this change uploads is shown until the server has it.
    public var pendingCoverAddress: String {
        PendingCover.address(forKey: key)
    }

    /// Replaces a temporary id by the real one in the path and the body.
    mutating func replaceID(_ temporary: Int, with real: Int) {
        path = path.split(separator: "/").map { $0 == String(temporary) ? String(real) : String($0) }.joined(separator: "/")
        repairs = repairs?.map { $0.replacing(temporary, with: real) }
        if let body, let value = try? JSONSerialization.jsonObject(with: body) {
            self.body = try? JSONValue.data(JSONValue.replacing(temporary, with: real, in: value))
        }
    }

    /// Whether the path or the body names the record with a temporary id.
    func refers(to temporary: Int) -> Bool {
        var copy = self
        copy.replaceID(temporary, with: 0)
        return copy != self
    }

    /// The request that delivers the change to the server at `serverURL`.
    public func urlRequest(serverURL: URL, token: String, upload data: Data? = nil) -> URLRequest {
        var request = URLRequest(url: ServerAddress.apiBaseURL(for: serverURL).appending(path: path))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(key, forHTTPHeaderField: "Idempotency-Key")
        request.setValue(JSONValue.timestamp(clientTime), forHTTPHeaderField: "X-Client-Time")
        if let upload, let data {
            let form = MultipartForm(field: upload.field, fileName: upload.fileName, mimeType: upload.mimeType, data: data)
            request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = form.encoded
        } else if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }
}

/// What came back when a change was sent.
public enum DeliveryResult: Sendable {
    /// The server answered.
    case response(status: Int, body: Data)
    /// No answer arrived.
    case unreachable
}

/// What to do with a change after it was sent.
public enum OutboxOutcome: Equatable, Sendable {
    /// The server took the change over; `body` is its answer.
    case delivered(body: Data)
    /// A later action or a deletion got in the way; the change is given up silently.
    case dropped
    /// The server refused the change for the stated reason; it is given up and the user is told.
    case rejected(message: String)
    /// The change stays queued and is sent again later.
    case retry

    private struct Failure: Decodable {
        let message: String?
        let code: String?
    }

    /// Classifies the result of sending a change.
    ///
    /// Success delivers. `409` with the code `stale` and `404` drop. Other client errors reject.
    /// A missing answer, a server error and an expired session keep the change for later.
    public init(_ result: DeliveryResult) {
        guard case let .response(status, body) = result else {
            self = .retry
            return
        }
        let failure = try? JSONDecoder().decode(Failure.self, from: body)
        switch status {
        case 200..<300:
            self = .delivered(body: body)
        case 404:
            self = .dropped
        case 409 where failure?.code == "stale":
            self = .dropped
        case 401, 408, 429, 500...:
            self = .retry
        default:
            self = .rejected(message: failure?.message ?? String(localized: "The server answered with an error (\(status)).", bundle: .kit))
        }
    }
}

/// The queue of changes on disk: one file for the entries and one per upload.
struct OutboxFiles {
    let directory: URL

    private var file: URL {
        directory.appending(path: "outbox.json")
    }

    /// Reads the queue; a missing or unreadable file gives an empty one.
    func load() -> [OutboxEntry] {
        (try? Data(contentsOf: file)).flatMap { try? JSONDecoder().decode([OutboxEntry].self, from: $0) } ?? []
    }

    /// Writes the queue atomically.
    func save(_ entries: [OutboxEntry]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(entries).write(to: file, options: .atomic)
    }

    /// The file that holds the upload of the change with `key`.
    func uploadFile(forKey key: String) -> URL {
        directory.appending(path: "\(key).upload")
    }

    /// Deletes the queue and its uploads.
    func wipe() {
        try? FileManager.default.removeItem(at: directory)
    }
}
