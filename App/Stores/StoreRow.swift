import DinnertimeKit
import SwiftUI

/// A shop with the number of offers noted for it and the switch that says whether the household buys there at the moment.
struct StoreRow: View {
    let store: Store
    let onSetActive: (Bool) -> Void

    var body: some View {
        Toggle(isOn: Binding(get: { store.isActive }, set: { onSetActive($0) })) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: store.name)
                if let count = store.offerCount {
                    Text("\(count) products")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
