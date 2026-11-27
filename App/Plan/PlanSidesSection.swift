import DinnertimeKit
import SwiftUI

/// The sides of a meal that is planned or changed, for dishes that are served with sides.
struct PlanSidesSection: View {
    let session: AppSession
    @Binding var draft: PlanEntryDraft

    var body: some View {
        if let dish = draft.recipe, dish.takesSides {
            Section {
                ForEach(draft.sides) { side in
                    HStack {
                        Text(verbatim: side.title)
                        Spacer()
                        Button("Remove", systemImage: "minus.circle") {
                            draft.sides.removeAll { $0.id == side.id }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .accessibilityValue(Text(verbatim: side.title))
                    }
                }
                NavigationLink {
                    SidePickerView(session: session, dish: dish, excludedIDs: Set(draft.sides.map(\.id))) { side in
                        draft.sides.append(side)
                    }
                } label: {
                    Label("Add side", systemImage: "plus")
                }
            } header: {
                Text("Sides")
            }
        }
    }
}
