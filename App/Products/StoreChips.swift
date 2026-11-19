import SwiftUI

/// The choice of where a package is sold: everywhere or at one of the known shops as chips to tap, and a field to type a new name.
struct StoreChips: View {
    /// Name of the chosen shop; empty for a size sold everywhere.
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

    /// Whether the name is typed: by choice, or because the chosen shop is none of the known ones.
    private var showsField: Bool {
        isTyping || !(selection.isEmpty || stores.contains(selection))
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
            Button("Known shops", systemImage: "xmark.circle.fill") {
                selection = ""
                isTyping = false
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.inkMuted)
        }
        .entryField()
        .onTapGesture {
            isFocused = true
        }
    }

    private var chips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    chip(for: "", title: Text("Everywhere"))
                    ForEach(stores, id: \.self) { store in
                        chip(for: store, title: Text(verbatim: store))
                    }
                    Button("New shop", systemImage: "plus") {
                        selection = ""
                        isTyping = true
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .padding(.horizontal, 14)
                    .frame(minHeight: EntryMetrics.chipHeight)
                    .foregroundStyle(.inkMuted)
                    .contentShape(.capsule)
                    .overlay {
                        Capsule()
                            .strokeBorder(.inkMuted, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: selection, initial: true) {
                proxy.scrollTo(selection)
            }
        }
    }

    /// A chip that chooses `store`; the empty name stands for everywhere.
    private func chip(for store: String, title: Text) -> some View {
        let isChosen = store == selection
        return Button {
            selection = store
            onChoose()
        } label: {
            title
                .font(.subheadline)
                .padding(.horizontal, 14)
                .frame(minHeight: EntryMetrics.chipHeight)
                .fontWeight(isChosen ? .semibold : .regular)
                .foregroundStyle(isChosen ? Color.onAccent : Color.ink)
                .background(isChosen ? Color.accent : Color.surface, in: .capsule)
                .overlay {
                    if !isChosen {
                        Capsule()
                            .strokeBorder(.line)
                    }
                }
        }
        .buttonStyle(.borderless)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
        .id(store)
    }
}
