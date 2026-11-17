import MealplannerKit
import SwiftUI

/// Finds a product and adds an amount of it to the pantry.
struct AddPantryItemView: View {
    private static var searchDelay: Duration { .milliseconds(300) }

    let onAdd: (PantryItemDraft) async -> Bool

    @State private var model: ProductSearchModel
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, onAdd: @escaping (PantryItemDraft) async -> Bool) {
        self.onAdd = onAdd
        _model = State(initialValue: ProductSearchModel(session: session))
    }

    var body: some View {
        NavigationStack {
            List(model.products) { product in
                NavigationLink(value: product) {
                    VStack(alignment: .leading) {
                        Text(verbatim: product.name)
                        if let section = product.storeSection {
                            Text(verbatim: section.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .overlay {
                if model.hasLoaded, model.products.isEmpty {
                    ContentUnavailableView.search(text: model.searchText)
                }
            }
            .searchable(text: $model.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search products")
            .navigationTitle("Add to pantry")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Product.self) { product in
                PantryItemForm(product: product, onAdd: onAdd) {
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task(id: model.searchText) {
                if model.hasLoaded {
                    try? await Task.sleep(for: Self.searchDelay)
                }
                if !Task.isCancelled {
                    await model.search()
                }
            }
            .errorAlert($model.errorMessage)
        }
    }
}
