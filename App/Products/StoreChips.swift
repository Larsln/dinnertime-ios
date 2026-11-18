import SwiftUI

/// The choice of a shop: the known ones as chips to tap, and a field to type a new name.
struct StoreChips: View {
    @Binding var selection: String
    /// Names of the shops the household buys at, in the order they are offered.
    let stores: [String]
    /// Called once a shop is chosen, to move on to the next field.
    let onChoose: () -> Void

    @State private var isTyping = false
    @FocusState private var isFocused: Bool

    var body: some View {
        Group {
            if showsField {
                field
            } else {
                chips
            }
        }
        .onChange(of: stores) {
            isTyping = false
        }
    }

    /// Whether the name is typed: by choice, without known shops, or because the chosen shop is none of them.
    private var showsField: Bool {
        isTyping || stores.isEmpty || !(selection.isEmpty || stores.contains(selection))
    }

    private var field: some View {
        HStack {
            TextField("Shop", text: $selection)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($isFocused)
                .onSubmit(onChoose)
                .onAppear {
                    isFocused = isTyping
                }
            if !stores.isEmpty {
                Button("Known shops", systemImage: "xmark.circle.fill") {
                    selection = ""
                    isTyping = false
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var chips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(stores, id: \.self) { store in
                        chip(for: store)
                    }
                    Button("New shop", systemImage: "plus") {
                        selection = ""
                        isTyping = true
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.tint.opacity(0.15), in: .capsule)
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: selection, initial: true) {
                proxy.scrollTo(selection)
            }
        }
    }

    private func chip(for store: String) -> some View {
        let isChosen = store == selection
        return Button {
            selection = store
            onChoose()
        } label: {
            Text(verbatim: store)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(isChosen ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
                .background(isChosen ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.15)), in: .capsule)
        }
        .buttonStyle(.borderless)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .id(store)
    }
}
