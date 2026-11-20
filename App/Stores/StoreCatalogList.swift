import DinnertimeKit
import SwiftUI

/// All shops of the household with the ways to prefer, pause, rename and delete them.
struct StoreCatalogList: View {
    @Bindable var model: StoreCatalogModel

    @State private var renamedStore: Store?
    @State private var deletedStore: Store?

    var body: some View {
        PaperList {
            Section {
                ForEach(model.stores) { store in
                    row(for: store)
                }
            } header: {
                if !model.stores.isEmpty {
                    Text("Starred stores decide which package sizes the shopping list uses. Other stores only count for what nothing else sells.")
                        .font(.footnote)
                        .foregroundStyle(.inkMuted)
                        .textCase(nil)
                }
            }
        }
        .overlay {
            if model.hasLoaded, model.stores.isEmpty {
                ContentUnavailableView("No stores", systemImage: "storefront", description: Text("Stores are added here or when you note where a product is sold."))
            }
        }
        .refreshesFromServer {
            await model.load()
        }
        .task {
            await model.load()
        }
        .renameStoreAlert($renamedStore) { store, name in
            Task {
                await model.rename(store, to: name)
            }
        }
        .confirmationDialog("Delete store", isPresented: deletionIsPresented, titleVisibility: .visible, presenting: deletedStore) { store in
            Button("Delete", role: .destructive) {
                Task {
                    await model.delete(store)
                }
            }
        } message: { store in
            Text("“\(store.name)” will be deleted together with what is noted for it.")
        }
        .errorAlert($model.errorMessage)
    }

    private func row(for store: Store) -> some View {
        StoreRow(store: store) { isPreferred in
            Task {
                await model.setPreferred(isPreferred, for: store)
            }
        } onSetActive: { isActive in
            Task {
                await model.setActive(isActive, for: store)
            }
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) {
                deletedStore = store
            }
            Button("Rename", systemImage: "pencil") {
                renamedStore = store
            }
        }
    }

    private var deletionIsPresented: Binding<Bool> {
        Binding(
            get: { deletedStore != nil },
            set: { if !$0 { deletedStore = nil } }
        )
    }
}
