import MealplannerKit
import SwiftUI

/// Shows the server, the account and the settings of the importer and offers to sign out.
struct SettingsView: View {
    let session: AppSession

    @Environment(\.dismiss) private var dismiss
    @State private var isSigningOut = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    if case let .signedIn(serverURL) = session.phase {
                        LabeledContent("Address", value: serverURL.absoluteString)
                    }
                }
                if let user = session.user {
                    Section("Account") {
                        LabeledContent("Name", value: user.name)
                        LabeledContent("Username", value: user.username)
                        if let email = user.email {
                            LabeledContent("Email", value: email)
                        }
                    }
                }
                HouseholdSettingsSection()
                ImportSettingsSection(session: session)
                Section {
                    Button("Sign out", role: .destructive) {
                        signOut()
                    }
                    .disabled(isSigningOut)
                } footer: {
                    Text(verbatim: "\(AppConfiguration.displayName) \(version)")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    private func signOut() {
        isSigningOut = true
        Task {
            await session.signOut()
        }
    }
}
