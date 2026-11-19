import AuthenticationServices
import DinnertimeKit
import SwiftUI

/// Sign-in to the server that was chosen during setup.
struct SignInView: View {
    @State private var model: SignInModel
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession

    init(session: AppSession, connection: ServerConnection) {
        _model = State(initialValue: SignInModel(session: session, connection: connection))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username", text: $model.username)
                        .accessibilityIdentifier("username")
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $model.password)
                        .accessibilityIdentifier("password")
                        .textContentType(.password)
                        .onSubmit(signIn)
                } footer: {
                    Text(verbatim: model.connection.url.absoluteString)
                }
                Section {
                    Button("Sign in", action: signIn)
                        .frame(maxWidth: .infinity)
                        .disabled(!model.canSignIn)
                    if let provider = model.connection.info.oidcProvider {
                        Button("Sign in with single sign-on") {
                            signIn(at: provider)
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(model.isSigningIn)
                    }
                }
                Section {
                    Button("Use a different server", action: model.changeServer)
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(Text(verbatim: model.connection.info.name))
            .errorAlert($model.errorMessage)
        }
    }

    private func signIn() {
        Task {
            await model.signIn()
        }
    }

    private func signIn(at provider: OIDCConfiguration) {
        Task {
            await model.signIn(at: provider, using: webAuthenticationSession)
        }
    }
}
