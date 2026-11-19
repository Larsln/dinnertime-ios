import DinnertimeKit
import SwiftUI

/// The shopping list as tiles: the open items by area of the store, the checked ones in a last section.
///
/// On narrow screens the details of an item open as a sheet. On wide screens more tiles stand in a row
/// and the details of the chosen item stand in a panel at the right.
struct ShoppingBoard: View {
    private static let spacing: CGFloat = 8
    private static let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 4)
    private static let wideColumns = [GridItem(.adaptive(minimum: 92, maximum: 132), spacing: spacing)]

    let session: AppSession
    let list: ShoppingList
    let model: ShoppingModel

    @State private var detailedItem: ShoppingListItem?
    /// The item whose details the panel shows on wide screens.
    @State private var selectedID: Int?
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            HStack(spacing: 0) {
                tiles
                ShoppingDetailPanel(session: session, item: list.items.first { $0.id == selectedID }, onDelete: delete) { note, item in
                    saveNote(note, of: item)
                }
                .padding([.vertical, .trailing], ReadableMetrics.panelMargin)
            }
            .background(.paper)
        } else {
            tiles
                .sheet(item: $detailedItem) { item in
                    ShoppingItemDetails(session: session, item: item, onDelete: item.isManual ? { delete(item) } : nil) { note in
                        saveNote(note, of: item)
                    }
                }
        }
    }

    private var tiles: some View {
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
    }

    private func grid(of items: [ShoppingListItem], @ViewBuilder title: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            title()
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: sizeClass == .regular ? Self.wideColumns : Self.columns, alignment: .leading, spacing: Self.spacing) {
                ForEach(items) { item in
                    ShoppingTile(item: item, isSelected: sizeClass == .regular && item.id == selectedID) {
                        Task {
                            await model.toggle(item)
                        }
                    } onShowDetails: {
                        showDetails(of: item)
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

    /// Shows the details in the panel on wide screens, else as a sheet.
    private func showDetails(of item: ShoppingListItem) {
        if sizeClass == .regular {
            selectedID = item.id
        } else {
            detailedItem = item
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
