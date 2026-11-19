import DinnertimeKit
import SwiftUI

/// Asks for the new name of a shop in an alert.
private struct RenameStoreAlert: ViewModifier {
    @Binding var store: Store?
    let onRename: (Store, String) -> Void

    @State private var name = ""

    func body(content: Content) -> some View {
        content
            .alert("Rename store", isPresented: isPresented, presenting: store) { store in
                TextField("Name", text: $name)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    if let name = ProductOffer.storedStore(name) {
                        onRename(store, name)
                    }
                }
            }
            .onChange(of: store) { _, store in
                name = store?.name ?? name
            }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { store != nil },
            set: { if !$0 { store = nil } }
        )
    }
}

extension View {
    /// Presents an alert that renames `store` and clears it when the alert is dismissed.
    func renameStoreAlert(_ store: Binding<Store?>, onRename: @escaping (Store, String) -> Void) -> some View {
        modifier(RenameStoreAlert(store: store, onRename: onRename))
    }
}
