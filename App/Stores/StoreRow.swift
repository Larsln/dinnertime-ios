import DinnertimeKit
import SwiftUI

/// A shop with the number of offers noted for it, a star for the shops the household usually goes to and a
/// switch for whether it buys there at the moment.
struct StoreRow: View {
    let store: Store
    let onSetPreferred: (Bool) -> Void
    let onSetActive: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button {
                onSetPreferred(!store.isPreferred)
            } label: {
                Image(systemName: store.isPreferred ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundStyle(store.isPreferred ? Color.accent : Color.inkMuted)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("preferred")
            .accessibilityAddTraits(store.isPreferred ? .isSelected : [])
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: store.name)
                if let count = store.offerCount {
                    Text("\(count) products")
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            control("active", isOn: store.isActive, onSet: onSetActive)
        }
    }

    /// A switch with its name below it.
    private func control(_ title: LocalizedStringKey, isOn: Bool, onSet: @escaping (Bool) -> Void) -> some View {
        VStack(spacing: 3) {
            Toggle(title, isOn: Binding(get: { isOn }, set: { onSet($0) }))
                .labelsHidden()
                .tint(.herb)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.inkMuted)
                .accessibilityHidden(true)
        }
    }
}
