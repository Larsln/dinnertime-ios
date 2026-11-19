import DinnertimeKit
import SwiftUI

/// A searchable, paginated list of recipes with a caller-defined row and, above the recipes, what the caller puts there.
///
/// What stands above the recipes makes way while a search text or a filter narrows the list; the filters that are
/// switched on stand there as chips instead. Without recipes the list says so in a row. Next to other content the list
/// carries its own search field, where the search bar of the system would span that content as well.
struct RecipeSearchList<Header: View, Row: View>: View {
    private static var searchDelay: Duration { .milliseconds(300) }

    @Bindable var model: RecipeListModel
    /// The recipe whose row is drawn as selected.
    var selectedID: Int?
    /// Whether the search field sits above the list instead of in the navigation bar.
    var searchesInline = false
    @ViewBuilder let header: Header
    @ViewBuilder let row: (RecipeSummary) -> Row

    var body: some View {
        List {
            if model.query.isFiltered {
                RecipeActiveFilters(model: model)
            }
            if !model.query.isNarrowed {
                header
            }
            if model.hasLoaded, model.recipes.isEmpty {
                RecipeEmptyRow(isNarrowed: model.query.isNarrowed) {
                    model.query = RecipeListModel.Query()
                }
            }
            ForEach(model.recipes) { recipe in
                row(recipe)
                    .cardRow(recipe.id == selectedID ? .accentSoft : .surface)
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
        .modifier(RecipeSearch(text: $model.query.text, isInline: searchesInline))
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

/// Searches the recipes with a field above the list or with the search bar of the system.
private struct RecipeSearch: ViewModifier {
    @Binding var text: String
    let isInline: Bool

    func body(content: Content) -> some View {
        if isInline {
            content.safeAreaInset(edge: .top, spacing: 0) {
                SearchField(prompt: "Search", text: $text)
                    .padding(.horizontal, CardRowMetrics.margin)
                    .padding(.vertical, 8)
                    .background(.paper)
            }
        } else {
            content.searchable(text: $text)
        }
    }
}

extension RecipeSearchList where Header == EmptyView {
    /// A list with nothing above the recipes.
    init(model: RecipeListModel, @ViewBuilder row: @escaping (RecipeSummary) -> Row) {
        self.init(model: model, header: { EmptyView() }, row: row)
    }
}
