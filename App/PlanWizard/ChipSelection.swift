import SwiftUI

/// A multiple choice shown as removable chips, with a menu that adds one of the remaining options.
struct ChipSelection<ID: Hashable>: View {
    /// One thing that can be chosen.
    struct Option: Identifiable {
        let id: ID
        let name: String
    }

    let addTitle: LocalizedStringKey
    let options: [Option]
    @Binding var selection: [ID]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(options.filter { selection.contains($0.id) }) { option in
                Button {
                    selection.removeAll { $0 == option.id }
                } label: {
                    HStack(spacing: 4) {
                        Text(verbatim: option.name)
                        Image(systemName: "xmark.circle.fill")
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.tint.opacity(0.15), in: .capsule)
                }
                .buttonStyle(.borderless)
                .accessibilityHint("Remove")
            }
            Menu {
                ForEach(options.filter { !selection.contains($0.id) }) { option in
                    Button {
                        selection.append(option.id)
                    } label: {
                        Text(verbatim: option.name)
                    }
                }
            } label: {
                Label(addTitle, systemImage: "plus")
            }
        }
    }
}
