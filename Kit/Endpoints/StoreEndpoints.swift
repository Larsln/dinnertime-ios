import Foundation

/// The shops of the household.
public enum StoreEndpoints {
    private struct CreateBody: Encodable {
        let name: String
    }

    private struct UpdateBody: Encodable {
        let name: String?
        let isActive: Bool?
    }

    /// `GET /stores`: all shops by name.
    public static var list: Endpoint<[Store]> {
        .resource(.get, "stores")
    }

    /// `POST /stores`: adds an active shop; answers `422` for a name that exists already, ignoring case.
    public static func create(name: String) -> Endpoint<Store> {
        .resource(.post, "stores", body: CreateBody(name: name))
    }

    /// `PATCH /stores/{id}`: renames a shop.
    public static func rename(id: Int, to name: String) -> Endpoint<Store> {
        .resource(.patch, "stores/\(id)", body: UpdateBody(name: name, isActive: nil))
    }

    /// `PATCH /stores/{id}`: states whether the household buys at a shop at the moment.
    public static func setActive(_ isActive: Bool, id: Int) -> Endpoint<Store> {
        .resource(.patch, "stores/\(id)", body: UpdateBody(name: nil, isActive: isActive))
    }

    /// `DELETE /stores/{id}`: deletes a shop together with its offers.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "stores/\(id)")
    }
}
