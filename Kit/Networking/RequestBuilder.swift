import Foundation

/// Turns endpoints into URL requests for one server.
struct RequestBuilder: Sendable {
    /// Base URL of the API, ending in `/api/v1`.
    let baseURL: URL
    /// Bearer token of the signed-in user.
    let token: String?
    /// Languages preferred on the device, most preferred first.
    let languages: [String]

    /// Builds the request for an endpoint, including headers and the encoded body.
    func request<Response>(for endpoint: Endpoint<Response>) throws -> URLRequest {
        var url = baseURL.appending(path: endpoint.path)
        if !endpoint.query.isEmpty {
            url.append(queryItems: endpoint.query)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AcceptLanguage.header(for: languages), forHTTPHeaderField: "Accept-Language")
        if endpoint.requiresAuthentication, let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        switch endpoint.body {
        case let .json(value):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONCoding.makeEncoder().encode(value)
        case let .multipart(form):
            request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = form.encoded
        case nil:
            break
        }
        return request
    }
}
