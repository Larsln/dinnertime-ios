import Foundation

/// An API call in a form the local copy can answer: method, path, query and JSON body.
struct LocalRequest {
    let method: HTTPMethod
    /// Path below the API base, split at the slashes.
    let path: [String]
    let query: [String: String]
    let body: JSONObject
    /// The file of a multipart upload, if the call carries one.
    let upload: MultipartForm?

    init(method: HTTPMethod, path: String, query: [String: String] = [:], body: JSONObject = [:], upload: MultipartForm? = nil) {
        self.method = method
        self.path = path.split(separator: "/").map(String.init)
        self.query = query
        self.body = body
        self.upload = upload
    }

    /// Describes an endpoint; its JSON body is encoded the way the server would receive it.
    init<Response>(_ endpoint: Endpoint<Response>) throws {
        var body: JSONObject = [:]
        var upload: MultipartForm?
        switch endpoint.body {
        case let .json(value):
            body = try JSONValue.object(from: JSONCoding.makeEncoder().encode(value))
        case let .multipart(form):
            upload = form
        case nil:
            break
        }
        let query = Dictionary(endpoint.query.map { ($0.name, $0.value ?? "") }) { first, _ in first }
        self.init(method: endpoint.method, path: endpoint.path, query: query, body: body, upload: upload)
    }

    /// The path component at `index` as record id.
    func id(at index: Int) -> Int? {
        path.indices.contains(index) ? Int(path[index]) : nil
    }

    /// Whether the path consists of exactly these components; `*` stands for any id.
    func matches(_ method: HTTPMethod, _ pattern: String...) -> Bool {
        guard self.method == method, pattern.count == path.count else {
            return false
        }
        return zip(pattern, path).allSatisfy { $0 == "*" ? Int($1) != nil : $0 == $1 }
    }
}

/// What the local copy answered to a call.
struct LocalResult {
    /// JSON of the answer in the shape of the server; `nil` for answers without a body.
    var body: Any?
    /// The parts of the app whose data the call changed.
    var areas: Set<RealtimeArea> = []
    /// The change to send to the server later; `nil` for reads.
    var change: QueuedChange?
}

/// A write that was applied to the local copy and has to reach the server.
struct QueuedChange {
    /// Temporary ids of the records the call created, in the order the server answers with them.
    var created: [Int] = []
    /// Kind of the created records, when they are records of their own and not parts of another.
    var createdKind: RecordKind?
    /// The shopping item the change acts on, for the exchange between devices.
    var shoppingItem: Int?
}

extension Replica {
    /// Wraps a resource the way the server does.
    func resource(_ value: Any) -> JSONObject {
        ["data": value]
    }

    /// Wraps a list as one page that holds everything.
    func page(_ items: [JSONObject]) -> JSONObject {
        ["data": items, "meta": ["current_page": 1, "last_page": 1, "total": items.count]]
    }

    /// A failure in the shape of a server answer.
    func failure(_ status: Int, _ message: String? = nil) -> APIError {
        .server(status: status, message: message)
    }

    /// Sorts records by a text field the way lists are sorted on the server.
    func sorted(_ records: [JSONObject], by key: String) -> [JSONObject] {
        records.sorted { first, second in
            let order = (first[key] as? String ?? "").localizedStandardCompare(second[key] as? String ?? "")
            return order == .orderedSame ? (first.recordID ?? 0) < (second.recordID ?? 0) : order == .orderedAscending
        }
    }

    /// Whether `text` contains `search`, ignoring case; an empty search matches everything.
    func matches(_ text: String?, _ search: String?) -> Bool {
        guard let search, !search.isEmpty else {
            return true
        }
        return text?.range(of: search, options: .caseInsensitive) != nil
    }
}
