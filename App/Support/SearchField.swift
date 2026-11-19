import SwiftUI

/// A search field that sits in the layout, for screens where the system search bar would move other controls.
struct SearchField: View {
    let prompt: LocalizedStringKey
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.inkMuted)
            TextField(prompt, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !text.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.inkMuted)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(.sunken, in: .capsule)
    }
}
