import MealplannerKit
import SwiftUI

/// Opened and leftover products at home.
struct PantryView: View {
    let session: AppSession

    @State private var model: PantryModel
    @State private var showsAddSheet = false
    @State private var editedItem: PantryItem?

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: PantryModel(session: session))
    }

    var body: some View {
        NavigationStack {
            List(model.items) { item in
                Button {
                    editedItem = item
                } label: {
                    PantryRow(item: item)
                }
                .tint(.primary)
                .swipeActions {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task {
                            await model.delete(item)
                        }
                    }
                }
            }
            .overlay {
                if model.hasLoaded, model.items.isEmpty {
                    ContentUnavailableView("Pantry is empty", systemImage: "refrigerator", description: Text("Add opened packages so that the plan uses them up."))
                }
            }
            .navigationTitle("Pantry")
            .settingsToolbar(session: session)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add to pantry", systemImage: "plus") {
                        showsAddSheet = true
                    }
                }
            }
            .sheet(isPresented: $showsAddSheet) {
                AddPantryItemView(session: session, onAdd: model.add)
            }
            .sheet(item: $editedItem) { item in
                EditPantryAmountView(item: item, onSave: model.setAmount)
            }
            .refreshesFromServer {
                await model.load()
            }
            .task {
                await model.load()
            }
            .reloadsOnChange(of: .pantry) {
                await model.load()
            }
            .errorAlert($model.errorMessage)
        }
    }
}
