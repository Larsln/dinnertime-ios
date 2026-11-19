import DinnertimeKit
import SwiftUI

/// The shopping list as tiles: the open items by area of the store, the checked ones in a last section.
struct ShoppingBoard: View {
    private static let spacing: CGFloat = 8
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 4)

    let session: AppSession
    let list: ShoppingList
    let model: ShoppingModel

    @State private var detailedItem: ShoppingListItem?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ShoppingAddField(model: model)
                Text(verbatim: list.startsOn.rangeText(until: list.endsOn))
                    .font(.subheadline)
                    .foregroundStyle(.inkMuted)
                ForEach(list.openSections) { section in
                    grid(of: section.items) {
                        title(of: section.kind)
                            .sectionHeadingStyle()
                    }
                }
                if !list.checkedItems.isEmpty {
                    grid(of: list.checkedItems) {
                        Text("Done (\(list.checkedItems.count))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.doneMark)
                    }
                }
            }
            .padding()
        }
        .paperBackground()
        .sheet(item: $detailedItem) { item in
            ShoppingItemDetails(session: session, item: item, onDelete: item.isManual ? { delete(item) } : nil) { note in
                saveNote(note, of: item)
            }
        }
    }

    private func grid(of items: [ShoppingListItem], @ViewBuilder title: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            title()
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
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

    private func saveNote(_ note: String?, of item: ShoppingListItem) {
        guard let product = item.product else {
            return
        }
        Task {
            await model.setNote(note, of: product)
        }
    }

    private func delete(_ item: ShoppingListItem) {
        Task {
            await model.delete(item)
        }
    }
}
