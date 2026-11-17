import Foundation

/// Products and the review of suggested values.
public enum ProductEndpoints {
    /// `GET /products`: products whose name or alias contains `search`.
    public static func search(_ search: String) -> Endpoint<Page<Product>> {
        .plain(.get, "products", query: [URLQueryItem(name: "search", value: search)])
    }

    /// `GET /review`: one page of products awaiting confirmation.
    public static func review(page: Int = 1) -> Endpoint<Page<Product>> {
        .plain(.get, "review", query: [URLQueryItem(name: "page", value: String(page))])
    }

    /// `POST /products/{id}/confirm`: confirms a product with all conversions and packages.
    public static func confirm(id: Int) -> Endpoint<Product> {
        .resource(.post, "products/\(id)/confirm")
    }
}
