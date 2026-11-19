import Foundation
import Testing
@testable import DinnertimeKit

/// Parsing of the event stream and what follows from its events.
struct RealtimeTests {
    private func events(_ text: String) -> [ServerSentEvent] {
        var parser = ServerSentEventParser()
        return parser.consume(Array(text.utf8))
    }

    @Test func eventsEndWithAnEmptyLine() {
        let events = events("id: 1\ndata: {\"areas\":[\"shopping\"]}\n\ndata: second\n\n")

        #expect(events == [
            ServerSentEvent(name: nil, data: "{\"areas\":[\"shopping\"]}"),
            ServerSentEvent(name: nil, data: "second"),
        ])
    }

    @Test func unfinishedEventsAreHeldBack() {
        var parser = ServerSentEventParser()

        #expect(parser.consume(Array("data: first\n".utf8)).isEmpty)
        #expect(parser.consume(Array("\n".utf8)) == [ServerSentEvent(name: nil, data: "first")])
    }

    @Test func commentsAndUnknownFieldsAreIgnored() {
        #expect(events(":\n\n: heartbeat\n\nretry: 3000\n\n").isEmpty)
        #expect(events(": ping\ndata: x\nid: 7\n\n") == [ServerSentEvent(name: nil, data: "x")])
    }

    @Test func dataLinesAreJoinedAndNamesKept() {
        let events = events("event: update\ndata: one\ndata:two\ndata\n\n")

        #expect(events == [ServerSentEvent(name: "update", data: "one\ntwo\n")])
    }

    @Test func acceptsAllLineEndings() {
        #expect(events("data: a\r\n\r\ndata: b\r\rdata: c\n\n").map(\.data) == ["a", "b", "c"])
    }

    @Test func keepsColonsAndUnicodeInValues() {
        #expect(events("data: {\"a\": \"Käse: gut\"}\n\n").map(\.data) == ["{\"a\": \"Käse: gut\"}"])
    }

    @Test func readsTheChangedAreas() {
        let event = ServerSentEvent(name: nil, data: #"{"areas": ["shopping", "pantry", "future"]}"#)

        #expect(RealtimeArea.areas(in: event) == [.shopping, .pantry])
        #expect(RealtimeArea.areas(in: ServerSentEvent(name: nil, data: "hello")).isEmpty)
        #expect(RealtimeArea.areas(in: ServerSentEvent(name: nil, data: #"{"areas": "plan"}"#)).isEmpty)
    }

    @Test func streamRequestUsesTheAddressOfTheDevice() throws {
        let answer = Data(#"{"data":{"url":"http:\/\/localhost:8000\/.well-known\/mercure?match=household","token":"jwt"}}"#.utf8)
        let connection = try RealtimeEndpoints.connection.decode(answer)
        let request = connection.request(serverURL: try #require(URL(string: "https://meals.example.org")))

        #expect(request.url?.absoluteString == "https://meals.example.org/.well-known/mercure?match=household")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer jwt")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/event-stream")
    }

    @Test func streamRequestKeepsThePortOfTheServer() throws {
        let connection = try RealtimeEndpoints.connection.decode(Data(#"{"data":{"url":"/.well-known/mercure?match=household","token":"jwt"}}"#.utf8))
        let request = connection.request(serverURL: try #require(URL(string: "http://192.168.1.10:8000")))

        #expect(request.url?.absoluteString == "http://192.168.1.10:8000/.well-known/mercure?match=household")
    }

    @Test func backoffDoublesUpToHalfAMinute() {
        #expect((1...7).map(ReconnectBackoff.delay(beforeAttempt:)) == [1, 2, 4, 8, 16, 30, 30])
        #expect(ReconnectBackoff.delay(beforeAttempt: 0) == 1)
    }

    @Test func halfStarsAreOnePointEach() {
        #expect((0..<5).map { StarScale.fill(ofStar: $0, points: 7) } == [.full, .full, .full, .half, .empty])
        #expect((0..<5).map { StarScale.fill(ofStar: $0, points: 0) } == [.empty, .empty, .empty, .empty, .empty])
        #expect((0..<5).map { StarScale.fill(ofStar: $0, points: 10) } == [.full, .full, .full, .full, .full])
        #expect(StarScale.starCount == 5)
    }

    @Test func touchesMapToPoints() {
        #expect(StarScale.points(at: 0, width: 200) == 0)
        #expect(StarScale.points(at: 5, width: 200) == 1)
        #expect(StarScale.points(at: 20, width: 200) == 1)
        #expect(StarScale.points(at: 21, width: 200) == 2)
        #expect(StarScale.points(at: 150, width: 200) == 8)
        #expect(StarScale.points(at: 260, width: 200) == 10)
        #expect(StarScale.points(at: -30, width: 200) == 0)
        #expect(StarScale.points(at: 10, width: 0) == 0)
    }

    @Test func checkedItemsLeaveTheirSections() throws {
        let list = try ShoppingEndpoints.current.decode(Fixture.data("shopping-list"))

        #expect(list.checkedItems.map(\.title) == ["Schmand"])
        #expect(!list.openSections.flatMap(\.items).contains { $0.isChecked })
        #expect(list.openSections.flatMap(\.items).count + list.checkedItems.count == list.items.count)
        #expect(list.openSections.last?.kind == .freeText)
    }
}
