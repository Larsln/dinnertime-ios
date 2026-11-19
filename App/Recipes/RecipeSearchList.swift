import DinnertimeKit
import SwiftUI

/// A searchable, paginated list of recipes with a caller-defined row and, above the recipes, what the caller puts there.
///
/// What stands above the recipes makes way while a search text is entered.
struct RecipeSearchList<Header: View, Row: View>: View {
    private static var searchDelay: Duration { .milliseconds(300) }

    @Bindable var model: RecipeListModel
    @ViewBuilder let header: Header
    @ViewBuilder let row: (RecipeSummary) -> Row

    var body: some View {
        List {
            if model.query.text.isEmpty {
                header
            }
            ForEach(model.recipes) { recipe in
                row(recipe)
                    .cardRow()
            }
            if model.hasMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .task {
                        await model.loadMore()
                    }
            }
        }
        .listStyle(.plain)
        .paperBackground()
        .overlay {
            if model.hasLoaded, model.recipes.isEmpty {
                ContentUnavailableView("No recipes", systemImage: "book", description: Text("Import a recipe from a link or change the search."))
            }
        }
        .searchable(text: $model.query.text)
        .refreshesFromServer {
            await model.reload()
        }
        .task(id: model.query) {
            if model.hasLoaded {
                try? await Task.sleep(for: Self.searchDelay)
            }
            if !Task.isCancelled {
                await model.reload()
            }
        }
        .errorAlert($model.errorMessage)
    }
}

extension RecipeSearchList where Header == EmptyView {
    /// A list with nothing above the recipes.
    init(model: RecipeListModel, @ViewBuilder row: @escaping (RecipeSummary) -> Row) {
        self.init(model: model, header: { EmptyView() }, row: row)
    }
}
