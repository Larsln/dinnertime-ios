import DinnertimeKit
import SwiftUI

/// What a dinner round shows at the place the signed-in user stands in it.
struct DinnerRoundContent: View {
    private static let maxWidth: CGFloat = 420

    let model: DinnerRoundModel
    /// Whether a question is open that keeps the cards from taking votes.
    let isHeld: Bool
    let onPlan: () -> Void
    /// Closes the round; `startsAgain` leaves the user where a new round is started.
    let onClose: (_ startsAgain: Bool) -> Void

    var body: some View {
        switch model.phase {
        case .none where !model.hasLoaded:
            ProgressView()
        case .none:
            DinnerStartForm(isDisabled: model.isBusy) { options in
                Task {
                    await model.start(options)
                }
            }
        case .matched:
            if let recipe = model.round?.match {
                framed(DinnerMatchView(recipe: recipe, isDisabled: model.isBusy, onPlan: onPlan) {
                    onClose(false)
                })
            }
        case .voting, .second:
            if let deck = model.deck {
                framed(DinnerDeck(deck: deck, isSecondLook: model.phase == .second, isDisabled: model.isBusy || isHeld) { liked in
                    Task {
                        await model.decide(liked: liked)
                    }
                })
            }
        case .waiting:
            ContentUnavailableView(waitingTitle, systemImage: "hourglass", description: Text("This page moves on by itself once everyone is through."))
        case .exhausted:
            notice("Nothing for everyone this time", hint: "A new round brings other recipes.", action: "New round") {
                onClose(true)
            }
        case .empty:
            notice("No dinner recipe fits", hint: "Nothing is left with these limits. Close the round and start again with fewer of them.", action: "Close round") {
                onClose(false)
            }
        }
    }

    /// Names the members the round waits for, or the other person when the server names none.
    private var waitingTitle: String {
        let names = model.round?.membersBehind ?? []
        guard !names.isEmpty else {
            return String(localized: "Waiting for the other person …")
        }
        return String(localized: "Waiting for \(names.formatted(.list(type: .and))) …")
    }

    private func framed(_ content: some View) -> some View {
        content
            .frame(maxWidth: Self.maxWidth)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func notice(_ title: LocalizedStringKey, hint: LocalizedStringKey, action: LocalizedStringKey, perform: @escaping () -> Void) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "fork.knife")
        } description: {
            Text(hint)
        } actions: {
            Button(action, action: perform)
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy)
        }
    }
}
