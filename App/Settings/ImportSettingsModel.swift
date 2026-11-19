import Foundation
import DinnertimeKit
import Observation

/// Loads and changes the settings of the importer.
@MainActor
@Observable
final class ImportSettingsModel: ErrorReporting {
    var errorMessage: String?
    private(set) var settings: ImportSettings?
    private(set) var isWorking = false

    private let session: AppSession

    init(session: AppSession) {
        self.session = session
    }

    /// Loads the current settings.
    func load() async {
        await attempt {
            settings = try await session.send(ImportSettingsEndpoints.settings)
        }
    }

    /// Switches the user agent of a browser on or off; the change shows at once and is undone if the server rejects it.
    func setIdentifyAsBrowser(_ identifyAsBrowser: Bool) async {
        let previous = settings
        settings?.identifyAsBrowser = identifyAsBrowser
        do {
            settings = try await session.send(ImportSettingsEndpoints.setIdentifyAsBrowser(identifyAsBrowser))
        } catch {
            settings = previous
            report(error)
        }
    }

    /// Uploads the cookie file the user picked.
    func uploadCookies(from picked: Result<URL, any Error>) async {
        await work {
            let url = try picked.get()
            let isScoped = url.startAccessingSecurityScopedResource()
            defer {
                if isScoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            settings = try await session.send(ImportSettingsEndpoints.uploadCookies(try Data(contentsOf: url)))
        }
    }

    /// Removes the stored cookie file.
    func deleteCookies() async {
        await work {
            settings = try await session.send(ImportSettingsEndpoints.deleteCookies)
        }
    }

    private func work(_ operation: () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        await attempt(operation)
    }
}
