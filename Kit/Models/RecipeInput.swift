/// The editable content of a recipe as `POST /recipes` and `PATCH /recipes/{id}` accept it.
///
/// Empty values are sent as `null` so that they clear what the server stores, and the
/// lists replace the stored ones as a whole.
public struct RecipeInput: Encodable, Equatable, Sendable {
    /// One line of the ingredient list; without a product it only carries `rawText`.
    public struct Ingredient: Encodable, Equatable, Sendable {
        public var section: String?
        public var productID: Int?
        public var quantity: Double?
        public var unitID: Int?
        public var note: String?
        public var isEstimated: Bool
        public var rawText: String?

        public init(section: String?, productID: Int?, quantity: Double?, unitID: Int?, note: String?, isEstimated: Bool, rawText: String?) {
            self.section = section
            self.productID = productID
            self.quantity = quantity
            self.unitID = unitID
            self.note = note
            self.isEstimated = isEstimated
            self.rawText = rawText
        }

        private enum CodingKeys: String, CodingKey {
            case section, quantity, note, isEstimated, rawText
            case productID = "productId"
            case unitID = "unitId"
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(section, forKey: .section)
            try container.encode(productID, forKey: .productID)
            try container.encode(quantity, forKey: .quantity)
            try container.encode(unitID, forKey: .unitID)
            try container.encode(note, forKey: .note)
            try container.encode(isEstimated, forKey: .isEstimated)
            try container.encode(rawText, forKey: .rawText)
        }
    }

    /// One step of the instructions.
    public struct Step: Encodable, Equatable, Sendable {
        /// Heading of the component the step belongs to.
        public var section: String?
        public var text: String

        public init(section: String?, text: String) {
            self.section = section
            self.text = text
        }

        private enum CodingKeys: String, CodingKey {
            case section, text
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(section, forKey: .section)
            try container.encode(text, forKey: .text)
        }
    }

    public var title: String
    public var description: String?
    /// Key of the course.
    public var course: String?
    /// Key of what the recipe is based on as a side dish.
    public var sideKind: String?
    /// Keys of the kinds of side the dish is served with.
    public var sideOptions: [String]
    public var servings: Int?
    public var yieldText: String?
    public var prepMinutes: Int?
    public var cookMinutes: Int?
    public var sourceURL: String?
    /// All tags of the recipe; sending them locks the tags against later changes by the server.
    public var tagIDs: [Int]
    /// The tools of the recipe from the catalog of the household.
    public var toolIDs: [Int]
    public var ingredients: [Ingredient]
    public var steps: [Step]

    public init(
        title: String,
        description: String? = nil,
        course: String? = nil,
        sideKind: String? = nil,
        sideOptions: [String] = [],
        servings: Int? = nil,
        yieldText: String? = nil,
        prepMinutes: Int? = nil,
        cookMinutes: Int? = nil,
        sourceURL: String? = nil,
        tagIDs: [Int] = [],
        toolIDs: [Int] = [],
        ingredients: [Ingredient] = [],
        steps: [Step] = []
    ) {
        self.title = title
        self.description = description
        self.course = course
        self.sideKind = sideKind
        self.sideOptions = sideOptions
        self.servings = servings
        self.yieldText = yieldText
        self.prepMinutes = prepMinutes
        self.cookMinutes = cookMinutes
        self.sourceURL = sourceURL
        self.tagIDs = tagIDs
        self.toolIDs = toolIDs
        self.ingredients = ingredients
        self.steps = steps
    }

    private enum CodingKeys: String, CodingKey {
        case title, description, course, sideKind, sideOptions, servings, yieldText, prepMinutes, cookMinutes, ingredients, steps
        case sourceURL = "sourceUrl"
        case tagIDs = "tagIds"
        case toolIDs = "toolIds"
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(course, forKey: .course)
        try container.encode(sideKind, forKey: .sideKind)
        try container.encode(sideOptions, forKey: .sideOptions)
        try container.encode(servings, forKey: .servings)
        try container.encode(yieldText, forKey: .yieldText)
        try container.encode(prepMinutes, forKey: .prepMinutes)
        try container.encode(cookMinutes, forKey: .cookMinutes)
        try container.encode(sourceURL, forKey: .sourceURL)
        try container.encode(tagIDs, forKey: .tagIDs)
        try container.encode(toolIDs, forKey: .toolIDs)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(steps, forKey: .steps)
    }
}
