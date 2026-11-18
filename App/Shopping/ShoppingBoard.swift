import MealplannerKit
import SwiftUI

/// The shopping list as tiles: the open items by area of the store, the checked ones in a last section.
struct ShoppingBoard: View {
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    let list: ShoppingList
    let model: ShoppingModel

    @State private var newItemLabel = ""
    @State private var detailedItem: ShoppingListItem?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                addField
                Text(verbatim: list.startsOn.rangeText(until: list.endsOn))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(list.openSections) { section in
                    grid(of: section.items) {
                        title(of: section.kind)
                    }
                }
                if !list.checkedItems.isEmpty {
                    grid(of: list.checkedItems) {
                        Text("Done (\(list.checkedItems.count))")
                    }
                }
            }
            .padding()
        }
        .sheet(item: $detailedItem) { item in
            ShoppingItemDetails(item: item, onDelete: item.isManual ? { delete(item) } : nil)
        }
    }

    private var addField: some View {
        HStack {
            TextField("Add item", text: $newItemLabel)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit(addItem)
            Button("Add", systemImage: "plus.circle.fill", action: addItem)
                .labelStyle(.iconOnly)
                .font(.title2)
                .disabled(newItemLabel.nilIfBlank == nil)
        }
    }

    private func grid(of items: [ShoppingListItem], @ViewBuilder title: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            title()
                .font(.headline)
            LazyVGrid(columns: Self.columns, spacing: 10) {
                ForEach(items) { item in
                    ShoppingTile(item: item) {
                        Task {
                            await model.toggle(item)
                        }
                    } onShowDetails: {
                        detailedItem = item
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

    private func addItem() {
        let label = newItemLabel
        newItemLabel = ""
        Task {
            await model.addItem(label: label)
        }
    }

    private func delete(_ item: ShoppingListItem) {
        Task {
            await model.delete(item)
        }
    }
}
