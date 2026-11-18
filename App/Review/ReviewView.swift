import MealplannerKit
import SwiftUI

/// The products that wait for confirmation, the catalog of all products and the tools of the household.
struct ReviewView: View {
    /// The lists the tab switches between.
    private enum Segment: Hashable {
        case review, products, tools
    }

    let session: AppSession

    @State private var model: ReviewModel
    @State private var catalog: ProductSearchModel
    @State private var tools: ToolCatalogModel
    @State private var segment = Segment.review

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: ReviewModel(session: session))
        _catalog = State(initialValue: ProductSearchModel(session: session))
        _tools = State(initialValue: ToolCatalogModel(session: session))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch segment {
                case .review:
                    ReviewList(model: model)
                case .products:
                    ProductCatalogList(model: catalog)
                case .tools:
                    ToolCatalogList(session: session, model: tools)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("List", selection: $segment) {
                    Text("To review (\(model.total))")
                        .tag(Segment.review)
                    Text("All products")
                        .tag(Segment.products)
                    Text("Tools")
                        .tag(Segment.tools)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Product.self) { product in
                ProductEditorView(session: session, product: product, onChange: reload)
            }
            .settingsToolbar(session: session)
            .task {
                await model.reload()
            }
            .reloadsOnChange(of: .products, reload: reload)
            .reloadsOnChange(of: .tools) {
                if tools.hasLoaded {
                    await tools.search()
                }
            }
            .errorAlert($model.errorMessage)
        }
    }

    private func reload() async {
        await model.reload()
        if catalog.hasLoaded {
            await catalog.search()
        }
    }
}
