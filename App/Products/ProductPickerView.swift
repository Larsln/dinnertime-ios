import DinnertimeKit
import SwiftUI

/// Lets the user search the products and choose one, optionally creating it from the typed name.
struct ProductPickerView: View {
    let allowsCreation: Bool
    let onSelect: (Product) -> Void

    @State private var model: ProductSearchModel
    @Environment(\.dismiss) private var dismiss

    init(session: AppSession, allowsCreation: Bool, onSelect: @escaping (Product) -> Void) {
        self.allowsCreation = allowsCreation
        self.onSelect = onSelect
        _model = State(initialValue: ProductSearchModel(session: session))
    }

    var body: some View {
        PaperList {
            ForEach(model.products) { product in
                Button {
                    choose(product)
                } label: {
                    ProductRow(product: product)
                }
                .tint(.ink)
            }
            if let name = creatableName {
                Button("Create “\(name)”", systemImage: "plus", action: create)
            }
            if model.hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .task {
                        await model.loadMore()
                    }
            }
        }
        .overlay {
            if model.hasLoaded, model.products.isEmpty, creatableName == nil {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
        .searchable(text: $model.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search products")
        .navigationTitle("Choose product")
        .navigationBarTitleDisplayMode(.inline)
        .debouncedSearch(model.searchText, isFirst: !model.hasLoaded, search: model.search)
        .errorAlert($model.errorMessage)
    }

    private var creatableName: String? {
        allowsCreation ? model.creatableName : nil
    }

    private func choose(_ product: Product) {
        onSelect(product)
        dismiss()
    }

    private func create() {
        Task {
            if let product = await model.create() {
                choose(product)
            }
        }
    }
}
