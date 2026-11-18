import Foundation

/// Access to the stream of change events.
public enum RealtimeEndpoints {
    /// `GET /realtime`: address and token of the stream; answers `404` on servers without realtime.
    public static var connection: Endpoint<RealtimeConnection> {
        .resource(.get, "realtime")
    }
}
