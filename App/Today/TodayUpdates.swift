import DinnertimeKit
import SwiftUI

/// Keeps the plan and the dinner round of today current: read when the screen appears and the app returns,
/// when the plan changes, when the server announces a change of the round, and at a slow pace while the
/// round waits for the others.
private struct TodayUpdates: ViewModifier {
    private static let pollInterval: Duration = .seconds(5)

    /// What decides whether the round is asked for at a slow pace.
    private struct Polling: Hashable {
        let isWaiting: Bool
        let isOnline: Bool
    }

    let model: TodayModel

    @Environment(OfflineCoordinator.self) private var offline
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .task(id: scenePhase == .active) {
                if scenePhase == .active {
                    await model.load()
                    await model.dinner.load()
                }
            }
            .reloadsOnChange(of: .plan) {
                await model.load()
            }
            .reloadsOnChange(of: .dinner) {
                await model.dinner.load()
            }
            .onChange(of: offline.isOnline) { _, isOnline in
                if isOnline {
                    Task {
                        await model.dinner.load()
                    }
                }
            }
            .task(id: Polling(isWaiting: model.dinner.phase.isPolled, isOnline: offline.isOnline)) {
                while model.dinner.phase.isPolled, offline.isOnline, !Task.isCancelled {
                    try? await Task.sleep(for: Self.pollInterval)
                    if !Task.isCancelled {
                        await model.dinner.load()
                    }
                }
            }
    }
}

extension View {
    /// Keeps the plan and the dinner round of `model` current while the view shows.
    func keepsTodayCurrent(_ model: TodayModel) -> some View {
        modifier(TodayUpdates(model: model))
    }
}
