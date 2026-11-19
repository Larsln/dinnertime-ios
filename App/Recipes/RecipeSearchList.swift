import DinnertimeKit
import SwiftUI

/// A searchable, paginated list of recipes with a caller-defined row.
struct RecipeSearchList<Row: View>: View {
    private static var searchDelay: Duration { .milliseconds(300) }

    @Bindable var model: RecipeListModel
    @ViewBuilder let row: (RecipeSummary) -> Row

    var body: some View {
        List {
            ForEach(model.recipes) { recipe in
                row(recipe)
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
