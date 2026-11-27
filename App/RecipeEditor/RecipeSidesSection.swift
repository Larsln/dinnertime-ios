import DinnertimeKit
import SwiftUI

/// What a recipe has to do with sides: the kind of side it is, or the kinds of side it is served with.
///
/// Hidden while the kinds are not known, for example with a server that does not know sides yet.
struct RecipeSidesSection: View {
    @Binding var draft: RecipeDraft
    let kinds: [SideKind]

    var body: some View {
        if !kinds.isEmpty {
            Section {
                Picker("Kind of side", selection: $draft.sideKind) {
                    Text("Not a side")
                        .tag(String?.none)
                    ForEach(kinds) { kind in
                        Text(verbatim: kind.name)
                            .tag(String?.some(kind.key))
                    }
                }
            } header: {
                Text("Sides")
            } footer: {
                if draft.sideKind != nil {
                    Text("The recipe is offered as a side for dishes that are served with this kind.")
                }
            }
            if draft.sideKind == nil {
                Section {
                    ForEach(kinds) { kind in
                        Toggle(isOn: isServed(with: kind)) {
                            Text(verbatim: kind.name)
                        }
                    }
                } header: {
                    Text("Fitting sides")
                } footer: {
                    Text("When you plan this dish, only sides of the kinds switched on are offered.")
                }
            }
        }
    }

    private func isServed(with kind: SideKind) -> Binding<Bool> {
        Binding {
            draft.sideOptions.contains(kind.key)
        } set: { served in
            if served {
                draft.sideOptions.insert(kind.key)
            } else {
                draft.sideOptions.remove(kind.key)
            }
        }
    }
}
