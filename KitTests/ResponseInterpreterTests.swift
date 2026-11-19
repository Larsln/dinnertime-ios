import Foundation
import Testing
@testable import DinnertimeKit

/// Mapping of HTTP answers to errors.
struct ResponseInterpreterTests {
    private func response(status: Int) throws -> HTTPURLResponse {
        let url = try #require(URL(string: "https://meals.example.org/api/v1/imports"))
        return try #require(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
    }

    @Test func passesSuccessfulBodies() throws {
        let data = Data("{}".utf8)

        #expect(try ResponseInterpreter.body(of: data, response: response(status: 202)) == data)
    }

    @Test func mapsUnauthorized() throws {
        let data = Data(#"{"message":"Unauthenticated."}"#.utf8)

        #expect(throws: APIError.unauthorized) {
            try ResponseInterpreter.body(of: data, response: response(status: 401))
        }
    }

    @Test func mapsValidationErrors() throws {
        let data = try Fixture.data("validation-error")
        let message = "The url field must be a valid URL."

        #expect(throws: APIError.validation(message: message, fields: ["url": [message]])) {
            try ResponseInterpreter.body(of: data, response: response(status: 422))
        }
    }

    @Test func mapsServerMessages() throws {
        let data = Data(#"{"message":"Already stocked."}"#.utf8)

        #expect(throws: APIError.server(status: 409, message: "Already stocked.")) {
            try ResponseInterpreter.body(of: data, response: response(status: 409))
        }
    }

    @Test func toleratesErrorsWithoutMessage() throws {
        #expect(throws: APIError.server(status: 404, message: nil)) {
            try ResponseInterpreter.body(of: Data(#"{"message":""}"#.utf8), response: response(status: 404))
        }
        #expect(throws: APIError.server(status: 502, message: nil)) {
            try ResponseInterpreter.body(of: Data("<html>".utf8), response: response(status: 502))
        }
    }

    @Test func validationDescriptionListsFieldMessages() {
        let error = APIError.validation(message: "First (and 1 more error)", fields: ["b": ["Second"], "a": ["First"]])

        #expect(error.errorDescription == "First\nSecond")
    }
}
