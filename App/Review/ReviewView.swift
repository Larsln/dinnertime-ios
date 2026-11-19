import DinnertimeKit
import SwiftUI

/// The products tab: the catalog of all products, the products whose estimated values wait
/// for confirmation, the tools of the household and the shops it buys at.
struct ReviewView: View {
    /// The lists the tab switches between.
    private enum Segment: Hashable {
        case products, review, tools, stores
    }

    let session: AppSession

    @State private var model: ReviewModel
    @State private var catalog: ProductSearchModel
    @State private var tools: ToolCatalogModel
    @State private var stores: StoreCatalogModel
    @State private var segment = Segment.products
    @State private var hasChosenSegment = false
    @State private var asksForName = false
    @State private var path = NavigationPath()

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: ReviewModel(session: session))
        _catalog = State(initialValue: ProductSearchModel(session: session))
        _tools = State(initialValue: ToolCatalogModel(session: session))
        _stores = State(initialValue: StoreCatalogModel(session: session))
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch segment {
                case .products:
                    ProductCatalogList(model: catalog)
                case .review:
                    ReviewList(model: model)
                case .tools:
                    ToolCatalogList(session: session, model: tools)
                case .stores:
                    StoreCatalogList(model: stores)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 8) {
                    Picker("List", selection: $segment) {
                        Text("All")
                            .tag(Segment.products)
                        Text("Review (\(model.total))")
                            .tag(Segment.review)
                        Text("Tools")
                            .tag(Segment.tools)
                        Text("Stores")
                            .tag(Segment.stores)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    switch segment {
                    case .products:
                        SearchField(prompt: "Search products", text: $catalog.searchText)
                    case .tools:
                        SearchField(prompt: "Search tools", text: $tools.searchText)
                    case .stores:
                        SearchField(prompt: "Search stores", text: $stores.searchText)
                    case .review:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.paper)
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Product.self) { product in
                ProductEditorView(session: session, product: product, onChange: reload)
            }
            .toolbar {
                if segment != .review {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(creationTitle, systemImage: "plus") {
                            asksForName = true
                        }
                    }
                }
            }
            .nameAlert(creationTitle, isPresented: $asksForName, onCreate: create)
            .task {
                await model.reload()
                chooseSegment()
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

    private var creationTitle: LocalizedStringKey {
        switch segment {
        case .tools: "New tool"
        case .stores: "New store"
        case .products, .review: "New product"
        }
    }

    /// Opens the review once when the tab is first shown and something waits there.
    private func chooseSegment() {
        guard !hasChosenSegment, model.hasLoaded else {
            return
        }
        hasChosenSegment = true
        if model.total > 0 {
            segment = .review
        }
    }

    /// Creates a tool, a shop, or a product whose editor opens at once.
    private func create(named name: String) {
        Task {
            switch segment {
            case .tools:
                await tools.create(name: name)
            case .stores:
                await stores.create(name: name)
            case .products, .review:
                if let product = await catalog.create(name: name) {
                    path.append(product)
                }
            }
        }
    }

    private func reload() async {
        await model.reload()
        if catalog.hasLoaded {
            await catalog.search()
        }
        if stores.hasLoaded {
            await stores.load()
        }
    }
}
