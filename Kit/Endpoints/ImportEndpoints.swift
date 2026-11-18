import Foundation

/// Imports of recipes from links.
public enum ImportEndpoints {
    private struct CreateBody: Encodable {
        let url: String
        let dishCount: Int?
    }

    /// `POST /imports`: queues the import of a link; without `dishCount` the server finds out how many dishes it shows.
    public static func create(url: URL, dishCount: Int? = nil) -> Endpoint<RecipeImport> {
        .resource(.post, "imports", body: CreateBody(url: url.absoluteString, dishCount: dishCount))
    }

    /// `GET /imports`: the most recent imports.
    public static var list: Endpoint<[RecipeImport]> {
        .resource(.get, "imports")
    }

    /// `GET /imports/{id}`: the current state of one import.
    public static func detail(id: Int) -> Endpoint<RecipeImport> {
        .resource(.get, "imports/\(id)")
    }

    /// `GET /imports/{id}/wait`: answers as soon as the import is completed or failed, at the latest after four minutes with its current state.
    public static func wait(id: Int) -> Endpoint<RecipeImport> {
        .resource(.get, "imports/\(id)/wait")
    }

    /// `POST /imports/{id}/retry`: queues a failed import again.
    public static func retry(id: Int) -> Endpoint<RecipeImport> {
        .resource(.post, "imports/\(id)/retry")
    }
}
