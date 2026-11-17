import SwiftUI

/// A date that can be switched off, shown as a toggle with a date picker below it.
struct OptionalDatePicker: View {
    let title: LocalizedStringKey
    @Binding var date: Date?

    var body: some View {
        Toggle(title, isOn: isSet)
        if let date {
            DatePicker(title, selection: Binding(get: { date }, set: { self.date = $0 }), displayedComponents: .date)
                .labelsHidden()
        }
    }

    private var isSet: Binding<Bool> {
        Binding(
            get: { date != nil },
            set: { date = $0 ? .now : nil }
        )
    }
}
