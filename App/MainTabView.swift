import SwiftUI

/// The areas of the app for a signed-in user.
struct MainTabView: View {
    /// The tabs, so that one area can switch to another.
    private enum Area: Hashable {
        case recipes, plan, shopping, pantry, review
    }

    let session: AppSession

    @State private var area = Area.recipes
    @State private var router = ImportRouter.shared
    @State private var realtime: RealtimeClient
    @Environment(\.scenePhase) private var scenePhase

    init(session: AppSession) {
        self.session = session
        _realtime = State(initialValue: RealtimeClient(session: session))
    }
    @State private var weekSelection = WeekSelection()

    var body: some View {
        TabView(selection: $area) {
            Tab("Recipes", systemImage: "book", value: Area.recipes) {
                RecipeListView(session: session)
            }
            Tab("Plan", systemImage: "calendar", value: Area.plan) {
                PlanView(session: session, selection: weekSelection) {
                    area = .shopping
                }
            }
            Tab("Shopping", systemImage: "cart", value: Area.shopping) {
                ShoppingView(session: session, selection: weekSelection)
            }
            Tab("Pantry", systemImage: "refrigerator", value: Area.pantry) {
                PantryView(session: session)
            }
            Tab("Review", systemImage: "checklist", value: Area.review) {
                ReviewView(session: session)
            }
        }
        .environment(realtime)
        .task(id: scenePhase == .active) {
            if scenePhase == .active {
                await realtime.run()
            }
        }
        .onChange(of: router.destination, initial: true) { _, destination in
            if destination != nil {
                area = .recipes
            }
        }
    }
}
