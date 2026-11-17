import MealplannerKit
import SwiftUI

/// The current shopping list, grouped by the areas of the store.
struct ShoppingView: View {
    let session: AppSession
    let selection: WeekSelection

    @State private var model: ShoppingModel
    @State private var showsItemPrompt = false
    @State private var newItemLabel = ""

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
                .alert("Add item", isPresented: $showsItemPrompt) {
                    TextField("Name", text: $newItemLabel)
                    Button("Add", action: addItem)
                    Button("Cancel", role: .cancel) {}
                }
                .refreshable {
                    await model.load()
                }
                .task {
                    await model.load()
                }
                .errorAlert($model.errorMessage)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let list = model.list {
            List {
                Section {
                    LabeledContent("Period", value: list.startsOn.rangeText(until: list.endsOn))
                }
                ForEach(list.sections) { section in
                    Section {
                        ForEach(section.items) { item in
                            row(for: item)
                        }
                    } header: {
                        title(of: section.kind)
                    }
                }
            }
        } else if model.hasLoaded {
            ContentUnavailableView {
                Label("No shopping list", systemImage: "cart")
            } description: {
                Text("Create a list from the plan of the selected week.")
            } actions: {
                Button(updateTitle, action: update)
                    .disabled(model.isWorking)
            }
        } else {
            ProgressView()
        }
    }

    private var actions: some View {
        Menu("Actions", systemImage: "ellipsis.circle") {
            Button(updateTitle, systemImage: "arrow.clockwise", action: update)
            Button("Add item", systemImage: "plus") {
                newItemLabel = ""
                showsItemPrompt = true
            }
            .disabled(model.list == nil)
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

    private func row(for item: ShoppingListItem) -> some View {
        ShoppingItemRow(item: item) {
            Task {
                await model.toggle(item)
            }
        }
        .swipeActions {
            if item.isManual {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    Task {
                        await model.delete(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func title(of kind: ShoppingSection.Kind) -> some View {
        switch kind {
        case let .store(section):
            Text(verbatim: section.name)
        case .unassigned:
            Text("Other products")
        case .freeText:
            Text("Other items")
        }
    }

    private func update() {
        Task {
            await model.update(for: selection.week)
        }
    }

    private func addItem() {
        Task {
            await model.addItem(label: newItemLabel)
        }
    }
}
