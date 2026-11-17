import Foundation

/// Description of one API call together with the way its answer is decoded.
public struct Endpoint<Response: Sendable>: Sendable {
    /// HTTP method of the call.
    public let method: HTTPMethod
    /// Path below the API base, without a leading slash.
    public let path: String
    /// Query parameters appended to the path.
    public let query: [URLQueryItem]
    /// JSON body, encoded with snake case keys.
    public let body: (any Encodable & Sendable)?
    /// Whether the bearer token is sent along.
    public let requiresAuthentication: Bool
    /// Turns the body of a successful answer into the response value.
    let decode: @Sendable (Data) throws -> Response

    init(
        _ method: HTTPMethod,
        _ path: String,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil,
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
        Endpoint(method, path, query: query, body: body) { data in
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
        Endpoint(method, path, query: query, body: body, requiresAuthentication: requiresAuthentication) { data in
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
