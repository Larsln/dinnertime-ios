import Foundation

/// A part of the data of the household that the server reports changes of.
public enum RealtimeArea: String, Decodable, CaseIterable, Sendable {
    case shopping, pantry, plan, recipes, products, tools
    /// The dinner round of today, which is not part of the local copy and is read from the server.
    case dinner

    /// Whether changes of the area reach the device through the sync feed.
    public var isSynced: Bool {
        self != .dinner
    }

    /// Body of a change event: `{"areas": [...]}`.
    private struct Change: Decodable {
        let areas: [String]
    }

    /// The areas an event names; areas this version does not know and events of another shape give none.
    public static func areas(in event: ServerSentEvent) -> Set<RealtimeArea> {
        guard let change = try? JSONDecoder().decode(Change.self, from: Data(event.data.utf8)) else {
            return []
        }
        return Set(change.areas.compactMap(RealtimeArea.init(rawValue:)))
    }
}
