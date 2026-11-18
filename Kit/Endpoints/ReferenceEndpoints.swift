import Foundation

/// Built-in and household-wide lists that recipes and products refer to.
public enum ReferenceEndpoints {
    /// `GET /courses`: all courses in the requested language.
    public static var courses: Endpoint<[Course]> {
        .resource(.get, "courses")
    }

    /// `GET /tags`: all tags in the requested language.
    public static var tags: Endpoint<[Tag]> {
        .resource(.get, "tags")
    }

    /// `GET /units`: the units recipes state quantities in.
    public static var units: Endpoint<[MeasureUnit]> {
        .resource(.get, "units")
    }

    /// `GET /store-sections`: the areas of the store in walking order.
    public static var storeSections: Endpoint<[StoreSection]> {
        .resource(.get, "store-sections")
    }
}
