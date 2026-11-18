import MealplannerKit
import SwiftUI

/// A row with a menu to say how many dishes a video shows; by default the server finds out.
struct DishCountPicker: View {
    @Binding var selection: Int?

    var body: some View {
        LabeledContent {
            Picker(DishCount.title, selection: $selection) {
                ForEach(DishCount.choices, id: \.self) { count in
                    Text(verbatim: DishCount.label(for: count))
                        .tag(count)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        } label: {
            Text(verbatim: DishCount.title)
        }
    }
}
