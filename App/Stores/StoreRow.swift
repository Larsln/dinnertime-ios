import DinnertimeKit
import SwiftUI

/// A shop with the number of offers noted for it and two switches: whether the household usually goes there
/// and whether it buys there at the moment.
struct StoreRow: View {
    let store: Store
    let onSetPreferred: (Bool) -> Void
    let onSetActive: (Bool) -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: store.name)
                if let count = store.offerCount {
                    Text("\(count) products")
                        .font(.caption)
                        .foregroundStyle(.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            control("preferred", isOn: store.isPreferred, onSet: onSetPreferred)
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
