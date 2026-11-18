import Foundation

/// Products and the review of suggested values.
public enum ProductEndpoints {
    private struct NameBody: Encodable {
        let name: String
    }

    private struct MergeBody: Encodable {
        let into: Int
    }

    /// `GET /products`: one page of products whose name or alias contains `search`.
    public static func search(_ search: String, page: Int = 1) -> Endpoint<Page<Product>> {
        let query = [
            URLQueryItem(name: "search", value: search),
            URLQueryItem(name: "page", value: String(page)),
        ]
        return .plain(.get, "products", query: query)
    }

    /// `GET /products/{id}`: a product with its conversions and packages.
    public static func detail(id: Int) -> Endpoint<Product> {
        .resource(.get, "products/\(id)")
    }

    /// `POST /products`: creates a product from its name; the server suggests the other values.
    public static func create(name: String) -> Endpoint<Product> {
        .resource(.post, "products", body: NameBody(name: name))
    }

    /// `PATCH /products/{id}`: changes the values of a product.
    public static func update(id: Int, _ input: ProductInput) -> Endpoint<Product> {
        .resource(.patch, "products/\(id)", body: input)
    }

    /// `DELETE /products/{id}`: deletes a product; answers `409` while a recipe uses it.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "products/\(id)")
    }

    /// `GET /review`: one page of products awaiting confirmation.
    public static func review(page: Int = 1) -> Endpoint<Page<Product>> {
        .plain(.get, "review", query: [URLQueryItem(name: "page", value: String(page))])
    }

    /// `POST /products/{id}/confirm`: confirms a product with all conversions and packages.
    public static func confirm(id: Int) -> Endpoint<Product> {
        .resource(.post, "products/\(id)/confirm")
    }

    /// `POST /products/{id}/merge`: moves the recipe lines of a product to `targetID` and deletes it.
    public static func merge(id: Int, into targetID: Int) -> Endpoint<Product> {
        .resource(.post, "products/\(id)/merge", body: MergeBody(into: targetID))
    }
}
