import Foundation

/// Sends endpoints to one server and decodes the answers.
public struct APIClient: Sendable {
    private let builder: RequestBuilder
    private let session: URLSession

    /// Creates a client for the server at `serverURL`, optionally acting as the owner of `token`.
    public init(
        serverURL: URL,
        token: String? = nil,
        session: URLSession = .shared,
        languages: [String] = Locale.preferredLanguages
    ) {
        builder = RequestBuilder(baseURL: ServerAddress.apiBaseURL(for: serverURL), token: token, languages: languages)
        self.session = session
    }

    /// Performs the call and returns its decoded answer.
    ///
    /// Throws ``APIError`` for every failure except cancellation, which surfaces as `CancellationError`.
    public func send<Response>(_ endpoint: Endpoint<Response>) async throws -> Response {
        let request = try builder.request(for: endpoint)
        let (data, response) = try await load(request)
        let body = try ResponseInterpreter.body(of: data, response: response)
        do {
            return try endpoint.decode(body)
        } catch {
            throw APIError.invalidResponse
        }
    }

    /// Performs the call and returns the body of its answer undecoded, for callers that keep it.
    ///
    /// Throws like ``send(_:)``.
    public func body<Response>(of endpoint: Endpoint<Response>) async throws -> Data {
        let (data, response) = try await load(try builder.request(for: endpoint))
        return try ResponseInterpreter.body(of: data, response: response)
    }

    /// Sends a prepared request and reports the status and body of whatever came back.
    public func deliver(_ request: URLRequest) async -> DeliveryResult {
        guard let (data, response) = try? await session.data(for: request), let response = response as? HTTPURLResponse else {
            return .unreachable
        }
        return .response(status: response.statusCode, body: data)
    }

    /// The request of an endpoint, for transfers that run outside of this client.
    public func urlRequest<Response>(for endpoint: Endpoint<Response>) throws -> URLRequest {
        try builder.request(for: endpoint)
    }

    private func load(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.unreachable
        }
    }
}
