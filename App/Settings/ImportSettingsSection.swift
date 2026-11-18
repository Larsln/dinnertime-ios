import MealplannerKit
import SwiftUI
import UniformTypeIdentifiers

/// The settings of the importer: the user agent of a browser and the cookie file for video platforms.
struct ImportSettingsSection: View {
    @State private var model: ImportSettingsModel
    @State private var picksFile = false

    init(session: AppSession) {
        _model = State(initialValue: ImportSettingsModel(session: session))
    }

    var body: some View {
        Group {
            if let settings = model.settings {
                Section {
                    Toggle("Identify as a browser", isOn: Binding(get: { settings.identifyAsBrowser }, set: setIdentifyAsBrowser))
                } header: {
                    Text(String(localized: "settings.import", defaultValue: "Import"))
                } footer: {
                    Text("Some recipe sites turn the importer away. With this option the server fetches pages with the user agent of a browser.")
                }
                Section {
                    LabeledContent("Sign-in for video platforms") {
                        if settings.hasCookies {
                            Text("stored")
                        }
                    }
                    Button("Upload cookie file", systemImage: "square.and.arrow.up") {
                        picksFile = true
                    }
                    if settings.hasCookies {
                        Button("Remove", systemImage: "trash", role: .destructive) {
                            Task {
                                await model.deleteCookies()
                            }
                        }
                    }
                } footer: {
                    Text("Instagram shows some videos to signed-in users only. Export the cookies of a signed-in browser as cookies.txt (Netscape format) and upload the file here. Preferably use a secondary account.")
                }
                .disabled(model.isWorking)
            }
        }
        .fileImporter(isPresented: $picksFile, allowedContentTypes: [.plainText]) { picked in
            Task {
                await model.uploadCookies(from: picked)
            }
        }
        .task {
            await model.load()
        }
        .errorAlert($model.errorMessage)
    }

    private func setIdentifyAsBrowser(_ identifyAsBrowser: Bool) {
        Task {
            await model.setIdentifyAsBrowser(identifyAsBrowser)
        }
    }
}
