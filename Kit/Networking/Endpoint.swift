import Foundation

/// Description of one API call together with the way its answer is decoded.
public struct Endpoint<Response: Sendable>: Sendable {
    /// HTTP method of the call.
    public let method: HTTPMethod
    /// Path below the API base, without a leading slash.
    public let path: String
    /// Query parameters appended to the path.
    public let query: [URLQueryItem]
    /// Body sent along, if any.
    public let body: RequestBody?
    /// Whether the bearer token is sent along.
    public let requiresAuthentication: Bool
    /// Turns the body of a successful answer into the response value.
    let decode: @Sendable (Data) throws -> Response

    init(
        _ method: HTTPMethod,
        _ path: String,
        query: [URLQueryItem] = [],
        body: RequestBody? = nil,
        requiresAuthentication: Bool = true,
        decode: @escaping @Sendable (Data) throws -> Response
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.requiresAuthentication = requiresAuthentication
        self.decode = decode
    }
}

extension Endpoint where Response: Decodable {
    /// Endpoint whose answer is wrapped in `{"data": ...}`.
    static func resource(
        _ method: HTTPMethod,
        _ path: String,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil
    ) -> Endpoint {
        Endpoint(method, path, query: query, body: body.map(RequestBody.json)) { data in
            try JSONCoding.makeDecoder().decode(DataEnvelope<Response>.self, from: data).data
        }
    }

    /// Endpoint that uploads a file and answers with a resource wrapped in `{"data": ...}`.
    static func upload(_ path: String, form: MultipartForm) -> Endpoint {
        Endpoint(.post, path, body: .multipart(form)) { data in
            try JSONCoding.makeDecoder().decode(DataEnvelope<Response>.self, from: data).data
        }
    }

    /// Endpoint whose answer is the response value itself.
    static func plain(
        _ method: HTTPMethod,
        _ path: String,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil,
        requiresAuthentication: Bool = true
    ) -> Endpoint {
        Endpoint(method, path, query: query, body: body.map(RequestBody.json), requiresAuthentication: requiresAuthentication) { data in
            try JSONCoding.makeDecoder().decode(Response.self, from: data)
        }
    }
}

extension Endpoint where Response == Void {
    /// Endpoint that answers without a body.
    static func empty(_ method: HTTPMethod, _ path: String) -> Endpoint {
        Endpoint(method, path) { _ in }
    }
}
