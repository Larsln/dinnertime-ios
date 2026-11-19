import DinnertimeKit
import SwiftUI

/// Asks how tonight's dinner is decided and starts the round.
struct DinnerStartForm: View {
    let isDisabled: Bool
    let onStart: (DinnerRoundOptions) -> Void

    @State private var isSolo = false
    @State private var onlyAvailable = false
    @State private var isQuick = false

    var body: some View {
        PaperForm {
            Section {
                Picker("Who decides?", selection: $isSolo) {
                    Text("The two of us")
                        .tag(false)
                    Text("Just me")
                        .tag(true)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                Text("Who decides?")
            } footer: {
                Text("Everyone votes on the same recipes on their own device.")
            }
            Section {
                Toggle("Only what needs no shopping", isOn: $onlyAvailable)
                Toggle("At most \(DinnerRoundOptions.quickMinutes) minutes", isOn: $isQuick)
            }
            .tint(.herb)
            Section {
                Button {
                    onStart(options)
                } label: {
                    Text("Let’s go")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .disabled(isDisabled)
    }

    private var options: DinnerRoundOptions {
        DinnerRoundOptions(isSolo: isSolo, onlyAvailable: onlyAvailable, maxMinutes: isQuick ? DinnerRoundOptions.quickMinutes : nil)
    }
}
