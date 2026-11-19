import DinnertimeKit
import SwiftUI

/// The field that adds to the shopping list: it searches the products while the user types
/// and offers the matches and, below them, the typed text as it is.
struct ShoppingAddField: View {
    let model: ShoppingModel

    @State private var text = ""
    @State private var matches: [Product] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .foregroundStyle(.inkMuted)
                TextField("Add item", text: $text)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(addText)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 46)
            .surface(in: .field)
            if let typed = text.nilIfBlank {
                suggestions(for: typed)
            }
        }
        .task(id: text) {
            await search()
        }
    }

    private func suggestions(for typed: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(matches) { product in
                Button {
                    add(product)
                } label: {
                    row {
                        ProductIcon(key: product.icon, sectionKey: product.storeSection?.key)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.tint)
                        Text(verbatim: product.name)
                    }
                }
                Divider()
            }
            Button(action: addText) {
                row {
                    Image(systemName: "plus")
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.tint)
                    Text("Add “\(typed)”")
                }
            }
        }
        .buttonStyle(.plain)
        .surface(in: .field)
    }

    private func row(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 10, content: content)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
    }

    private func search() async {
        guard let typed = text.nilIfBlank else {
            matches = []
            return
        }
        try? await Task.sleep(for: .milliseconds(200))
        if !Task.isCancelled {
            matches = await model.products(matching: typed)
        }
    }

    private func add(_ product: Product) {
        clear()
        Task {
            await model.addItem(product)
        }
    }

    private func addText() {
        let label = text
        clear()
        Task {
            await model.addItem(label: label)
        }
    }

    private func clear() {
        text = ""
        matches = []
    }
}
