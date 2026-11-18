import MealplannerKit
import SwiftUI

/// The products tab: the catalog of all products, the products whose estimated values wait
/// for confirmation and the tools of the household.
struct ReviewView: View {
    /// The lists the tab switches between.
    private enum Segment: Hashable {
        case products, review, tools
    }

    let session: AppSession

    @State private var model: ReviewModel
    @State private var catalog: ProductSearchModel
    @State private var tools: ToolCatalogModel
    @State private var segment = Segment.products
    @State private var hasChosenSegment = false
    @State private var asksForName = false
    @State private var path = NavigationPath()

    init(session: AppSession) {
        self.session = session
        _model = State(initialValue: ReviewModel(session: session))
        _catalog = State(initialValue: ProductSearchModel(session: session))
        _tools = State(initialValue: ToolCatalogModel(session: session))
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
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("List", selection: $segment) {
                    Text("All products")
                        .tag(Segment.products)
                    Text("To review (\(model.total))")
                        .tag(Segment.review)
                    Text("Tools")
                        .tag(Segment.tools)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("Products")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Product.self) { product in
                ProductEditorView(session: session, product: product, onChange: reload)
            }
            .settingsToolbar(session: session)
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
        segment == .tools ? "New tool" : "New product"
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

    /// Creates a tool, or a product whose editor opens at once.
    private func create(named name: String) {
        Task {
            if segment == .tools {
                await tools.create(name: name)
            } else if let product = await catalog.create(name: name) {
                path.append(product)
            }
        }
    }

    private func reload() async {
        await model.reload()
        if catalog.hasLoaded {
            await catalog.search()
        }
    }
}
