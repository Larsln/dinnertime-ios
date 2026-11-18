import Foundation

/// The settings of the importer.
public enum ImportSettingsEndpoints {
    private struct BrowserBody: Encodable {
        let identifyAsBrowser: Bool
    }

    /// `GET /settings/import`: the current settings.
    public static var settings: Endpoint<ImportSettings> {
        .resource(.get, "settings/import")
    }

    /// `PATCH /settings/import`: switches the user agent of a browser on or off.
    public static func setIdentifyAsBrowser(_ identifyAsBrowser: Bool) -> Endpoint<ImportSettings> {
        .resource(.patch, "settings/import", body: BrowserBody(identifyAsBrowser: identifyAsBrowser))
    }

    /// `POST /settings/import/cookies`: stores a cookie file in Netscape format.
    public static func uploadCookies(_ file: Data) -> Endpoint<ImportSettings> {
        .upload("settings/import/cookies", form: MultipartForm(field: "cookies", fileName: "cookies.txt", mimeType: "text/plain", data: file))
    }

    /// `DELETE /settings/import/cookies`: removes the stored cookie file.
    public static var deleteCookies: Endpoint<ImportSettings> {
        .resource(.delete, "settings/import/cookies")
    }
}
