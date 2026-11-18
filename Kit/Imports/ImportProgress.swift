/// How far an import got, as a list of steps to show.
public enum ImportProgress {
    /// State of one step.
    public enum StepState: Equatable, Sendable {
        case done, active, upcoming
    }

    /// The state of `stage` for an import: stages before the current one are done, all are done once the import completed.
    ///
    /// A waiting import shows its first stage as active.
    public static func state(of stage: RecipeImport.Stage, in item: RecipeImport) -> StepState {
        let stages = RecipeImport.Stage.allCases
        let position = stages.firstIndex(of: stage) ?? 0
        switch item.status {
        case .completed:
            return .done
        case .failed:
            return .upcoming
        case .pending, .processing:
            let current = item.stage.flatMap(stages.firstIndex(of:)) ?? 0
            return position < current ? .done : position == current ? .active : .upcoming
        }
    }
}

extension RecipeImport.Stage {
    /// What the server is doing, in the language of the device.
    public var label: String {
        switch self {
        case .downloading: String(localized: "Loading the video", bundle: .kit)
        case .analyzing: String(localized: "Reading the recipe", bundle: .kit)
        case .saving: String(localized: "Saving", bundle: .kit)
        }
    }
}
