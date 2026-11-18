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
