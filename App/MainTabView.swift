import SwiftUI

/// The areas of the app for a signed-in user.
struct MainTabView: View {
    let session: AppSession

    @State private var weekSelection = WeekSelection()

    var body: some View {
        TabView {
            Tab("Recipes", systemImage: "book") {
                RecipeListView(session: session)
            }
            Tab("Plan", systemImage: "calendar") {
                PlanView(session: session, selection: weekSelection)
            }
            Tab("Shopping", systemImage: "cart") {
                ShoppingView(session: session, selection: weekSelection)
            }
            Tab("Pantry", systemImage: "refrigerator") {
                PantryView(session: session)
            }
            Tab("Review", systemImage: "checklist") {
                ReviewView(session: session)
            }
        }
    }
}
