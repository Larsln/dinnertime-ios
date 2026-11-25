import Foundation
import Testing
@testable import DinnertimeKit

/// The log of failures that can be exported.
struct ErrorLogTests {
    private func log() -> ErrorLog {
        ErrorLog(file: FileManager.default.temporaryDirectory.appending(path: "error-log-\(UUID().uuidString).json"))
    }

    @Test func entriesSurviveARestartNewestFirst() {
        let file = FileManager.default.temporaryDirectory.appending(path: "error-log-\(UUID().uuidString).json")
        let first = ErrorLog(file: file)
        first.record("one", context: "A", at: Date(timeIntervalSince1970: 10))
        first.record("two", context: "B", at: Date(timeIntervalSince1970: 20))

        let entries = ErrorLog(file: file).entries

        #expect(entries.map(\.message) == ["two", "one"])
        #expect(entries.map(\.context) == ["B", "A"])
    }

    @Test func theSameFailureIsNotedOnceWhenItPassesSeveralPlaces() {
        let log = log()
        log.record("same", context: "PATCH products/1", at: Date(timeIntervalSince1970: 10))
        log.record("same", context: "ProductEditorModel", at: Date(timeIntervalSince1970: 11))
        log.record("same", context: "PATCH products/1", at: Date(timeIntervalSince1970: 60))

        #expect(log.entries.count == 2)
    }

    @Test func onlyTheLatestEntriesAreKeptAndLongMessagesAreCut() {
        let log = log()
        for index in 0..<(ErrorLog.limit + 5) {
            log.record("failure \(index)", context: "T")
        }
        log.record(String(repeating: "x", count: 2000), context: "T")

        #expect(log.entries.count == ErrorLog.limit)
        #expect(log.entries.first?.message.count == ErrorLog.messageLimit)
        log.clear()
        #expect(log.entries.isEmpty)
    }

    @Test func callsAreNotedByMethodAndPathWithoutQueryAndNormalFailuresAreLeftOut() {
        let log = log()
        log.record(APIError.server(status: 500, message: "Boom"), of: ProductEndpoints.search("geheim"))
        log.record(APIError.validation(message: "Invalid", fields: ["unit": ["wrong"]]), of: ProductEndpoints.detail(id: 4))
        log.record(APIError.unreachable, of: ProductEndpoints.detail(id: 4))
        log.record(APIError.unauthorized, of: ProductEndpoints.detail(id: 4))
        log.record(CancellationError(), of: ProductEndpoints.detail(id: 4))

        #expect(log.entries.map(\.context) == ["GET products/4", "GET products"])
        #expect(log.entries.map(\.message) == ["HTTP 422: Invalid unit", "HTTP 500: Boom"])
    }

    @Test func theExportStartsWithTheHeaderAndListsOldestFirst() {
        let log = log()
        log.record("one", context: "A", at: Date(timeIntervalSince1970: 0))
        log.record("two", context: "B", at: Date(timeIntervalSince1970: 60))

        let lines = log.exportText(header: ["Dinnertime 1.0 (1)"]).split(separator: "\n", omittingEmptySubsequences: false)

        #expect(lines.first == "Dinnertime 1.0 (1)")
        #expect(lines[2] == "1970-01-01T00:00:00Z  [A]  one")
        #expect(lines[3] == "1970-01-01T00:01:00Z  [B]  two")
    }
}
