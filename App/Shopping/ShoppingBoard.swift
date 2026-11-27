import DinnertimeKit
import SwiftUI

/// The shopping list as tiles: the open items by area of the store, the checked and skipped ones in a last section.
/// If the household wants it, a note between them names what is at home already.
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
    @Environment(HouseholdStore.self) private var household

    var body: some View {
        if sizeClass == .regular {
            HStack(spacing: 0) {
                tiles
                ShoppingDetailPanel(session: session, item: list.items.first { $0.id == selectedID }, actions: actions(for:))
                    .padding([.vertical, .trailing], ReadableMetrics.panelMargin)
            }
            .background(.paper)
        } else {
            tiles
                .sheet(item: $detailedItem) { item in
                    ShoppingItemDetails(session: session, item: item, actions: actions(for: item))
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
                if household.showStockedNeeds, !list.inStock.isEmpty {
                    ShoppingStockNote(needs: list.inStock)
                }
                if !list.settledItems.isEmpty {
                    grid(of: list.settledItems) {
                        Text("Done (\(list.settledItems.count))")
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

    /// What the details of `item` can do about it.
    private func actions(for item: ShoppingListItem) -> ShoppingItemActions {
        ShoppingItemActions(
            delete: item.isManual ? { run { await model.delete(item) } } : nil,
            saveNote: { note in
                if let product = item.product {
                    run { await model.setNote(note, of: product) }
                }
            },
            setSkipped: { skipped in run { await model.setSkipped(skipped, item) } },
            substitute: { choice in run { await model.substitute(choice, for: item) } }
        )
    }

    private func run(_ change: @escaping () async -> Void) {
        Task {
            await change()
        }
    }
}
