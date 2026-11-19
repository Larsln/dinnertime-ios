import DinnertimeKit
import SwiftUI

/// The invitation to decide tonight's dinner together, or the state of the round that is running already.
///
/// Without a connection it says that deciding together needs the server and cannot be opened.
struct DinnerPrompt: View {
    let round: DinnerRound?
    /// Where the signed-in user stands in the round.
    let phase: DinnerPhase
    let isOnline: Bool
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if round != nil, isOnline {
                    Text("What do we eat tonight?")
                        .overlineStyle(.accentDeep)
                    Text(verbatim: state)
                        .brandFont(size: 22, relativeTo: .title2)
                        .foregroundStyle(.ink)
                } else {
                    Text("What do we eat tonight?")
                        .brandFont(size: 22, relativeTo: .title2)
                        .foregroundStyle(.ink)
                    hint
                        .font(.subheadline)
                        .foregroundStyle(.inkMuted)
                }
            }
            Button(action: onOpen) {
                Text(verbatim: action)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isOnline)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .surface(.accentSoft)
    }

    @ViewBuilder
    private var hint: some View {
        if isOnline {
            Text("Both of you say yes or no to a few recipes. The first one you both like is tonight’s dinner.")
        } else {
            Label("Deciding together needs a connection to the server.", systemImage: "wifi.slash")
        }
    }

    /// What the running round waits for.
    private var state: String {
        if phase == .matched {
            return String(localized: "Match: \(round?.match?.title ?? "")")
        }
        return phase.isVoting ? String(localized: "Round in progress – your turn") : String(localized: "Round in progress")
    }

    /// Name of the button that opens the round or starts one.
    private var action: String {
        guard round != nil, isOnline else {
            return String(localized: "Decide together")
        }
        if phase == .matched {
            return String(localized: "Show")
        }
        return phase.isVoting ? String(localized: "Vote") : String(localized: "Open")
    }
}
