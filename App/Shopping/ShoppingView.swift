import MealplannerKit
import SwiftUI

/// The current shopping list as tiles, grouped by the areas of the store.
struct ShoppingView: View {
    let session: AppSession
    let selection: WeekSelection

    @State private var model: ShoppingModel
    @Environment(OfflineCoordinator.self) private var offline

    init(session: AppSession, selection: WeekSelection) {
        self.session = session
        self.selection = selection
        _model = State(initialValue: ShoppingModel(session: session))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Shopping")
                .settingsToolbar(session: session)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        actions
                    }
                }
                .refreshesFromServer {
                    await model.load()
                }
                .task {
                    await model.load()
                }
                .onAppear(perform: offline.startSharingShoppingList)
                .onDisappear(perform: offline.stopSharingShoppingList)
                .reloadsOnChange(of: .shopping) {
                    await model.load()
                }
                .errorAlert($model.errorMessage)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let list = model.list {
            ShoppingBoard(list: list, model: model)
        } else if model.hasLoaded {
            ContentUnavailableView {
                Label("No shopping list", systemImage: "cart")
            } description: {
                Text("Create a list from the plan of the selected week.")
            } actions: {
                Button(updateTitle, action: update)
                    .disabled(model.isWorking || !offline.isOnline)
                if !offline.isOnline {
                    ConnectionHint()
                }
            }
        } else {
            ProgressView()
        }
    }

    private var actions: some View {
        Menu("Actions", systemImage: "ellipsis.circle") {
            Button(updateTitle, systemImage: offline.isOnline ? "arrow.clockwise" : "wifi.slash", action: update)
                .disabled(!offline.isOnline)
            Button("Stock leftovers", systemImage: "refrigerator") {
                Task {
                    await model.stockLeftovers()
                }
            }
            .disabled(!model.canStockLeftovers)
        }
        .disabled(model.isWorking)
    }

    private var updateTitle: String {
        model.covers(selection.week)
            ? String(localized: "Refresh list")
            : String(localized: "Create list for \(selection.week.rangeText)")
    }

    private func update() {
        Task {
            await model.update(for: selection.week)
        }
    }
}
