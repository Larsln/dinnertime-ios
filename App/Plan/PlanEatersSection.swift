import DinnertimeKit
import SwiftUI

/// Who eats a planned meal: the members of the household to switch on and off, and a number of guests.
struct PlanEatersSection: View {
    @Binding var draft: PlanEntryDraft
    let members: [HouseholdMember]

    var body: some View {
        Section {
            ForEach(members) { member in
                Toggle(isOn: isEating(member)) {
                    Text(verbatim: member.name)
                }
            }
            Stepper("Guests: \(draft.guests)", value: $draft.guests, in: PlanEntryDraft.guestRange)
        } header: {
            Text("Who eats")
        } footer: {
            Text("Guests count with a standard portion. Whoever rates portions gets a size of their own.")
        }
    }

    private func isEating(_ member: HouseholdMember) -> Binding<Bool> {
        Binding {
            draft.eaterIDs.contains(member.id)
        } set: { eats in
            if eats {
                draft.eaterIDs.insert(member.id)
            } else {
                draft.eaterIDs.remove(member.id)
            }
        }
    }
}
