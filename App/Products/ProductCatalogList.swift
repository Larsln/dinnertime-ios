import MealplannerKit
import SwiftUI

/// All products of the household, searchable by name or alias, each opening its editor.
struct ProductCatalogList: View {
    @Bindable var model: ProductSearchModel

    var body: some View {
        List {
            ForEach(model.products) { product in
                NavigationLink(value: product) {
                    ProductRow(product: product)
                }
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
            if model.hasLoaded, model.products.isEmpty {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
        .searchable(text: $model.searchText, prompt: "Search products")
        .refreshable {
            await model.search()
        }
        .debouncedSearch(model.searchText, isFirst: !model.hasLoaded, search: model.search)
        .errorAlert($model.errorMessage)
    }
}
