import Foundation

/// What a request carries in its body.
public enum RequestBody: Sendable {
    /// A value sent as JSON with snake case keys.
    case json(any Encodable & Sendable)
    /// A form that uploads one file.
    case multipart(MultipartForm)
}

/// A `multipart/form-data` body with a single file field.
public struct MultipartForm: Sendable {
    /// Name of the form field.
    public let field: String
    /// File name reported to the server.
    public let fileName: String
    /// Media type of the file.
    public let mimeType: String
    /// Contents of the file.
    public let data: Data
    /// Separator between the parts; must not occur in the file.
    public let boundary: String

    public init(field: String, fileName: String, mimeType: String, data: Data, boundary: String = "Boundary-\(UUID().uuidString)") {
        self.field = field
        self.fileName = fileName
        self.mimeType = mimeType
        self.data = data
        self.boundary = boundary
    }

    /// Value of the `Content-Type` header.
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    /// The encoded body.
    var encoded: Data {
        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"\(field)\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(data)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        return body
    }
}
