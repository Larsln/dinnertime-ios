import Foundation

/// The shops of the household.
public enum StoreEndpoints {
    private struct CreateBody: Encodable {
        let name: String
    }

    private struct UpdateBody: Encodable {
        let name: String?
        let isActive: Bool?
        let isPreferred: Bool?

        init(name: String? = nil, isActive: Bool? = nil, isPreferred: Bool? = nil) {
            self.name = name
            self.isActive = isActive
            self.isPreferred = isPreferred
        }
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
        .resource(.patch, "stores/\(id)", body: UpdateBody(name: name))
    }

    /// `PATCH /stores/{id}`: states whether the household buys at a shop at the moment.
    public static func setActive(_ isActive: Bool, id: Int) -> Endpoint<Store> {
        .resource(.patch, "stores/\(id)", body: UpdateBody(isActive: isActive))
    }

    /// `PATCH /stores/{id}`: states whether the household usually goes to a shop.
    public static func setPreferred(_ isPreferred: Bool, id: Int) -> Endpoint<Store> {
        .resource(.patch, "stores/\(id)", body: UpdateBody(isPreferred: isPreferred))
    }

    /// `DELETE /stores/{id}`: deletes a shop together with its offers.
    public static func delete(id: Int) -> Endpoint<Void> {
        .empty(.delete, "stores/\(id)")
    }
}
