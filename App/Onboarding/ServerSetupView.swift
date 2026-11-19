import DinnertimeKit
import SwiftUI

/// First screen of the app: asks which server the household uses.
struct ServerSetupView: View {
    @State private var model: ServerSetupModel

    init(session: AppSession) {
        _model = State(initialValue: ServerSetupModel(session: session))
    }

    var body: some View {
        NavigationStack {
            PaperForm {
                BrandMarkRow()
                Section {
                    TextField("Server address", text: $model.address, prompt: Text(verbatim: "https://meals.example.org"))
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit(connect)
                        .accessibilityIdentifier("server-address")
                } footer: {
                    Text("Enter the address of the server your household runs. Addresses outside your home network need HTTPS.")
                }
                Section {
                    Button(action: connect) {
                        if model.isConnecting {
                            ProgressView()
                        } else {
                            Text("Connect")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!model.canConnect)
                }
            }
            .navigationTitle(Text(verbatim: AppConfiguration.displayName))
            .errorAlert($model.errorMessage)
        }
    }

    private func connect() {
        Task {
            await model.connect()
        }
    }
}
