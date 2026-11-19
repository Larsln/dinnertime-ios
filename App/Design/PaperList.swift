import SwiftUI

/// A list on the background of the screens whose rows are drawn as surface.
struct PaperList<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        List {
            Group {
                content
            }
            .surfaceRows()
        }
        .paperBackground()
    }
}

extension PaperList {
    /// A list with one row for every element of `data`.
    init<Data: RandomAccessCollection, Row: View>(_ data: Data, @ViewBuilder row: @escaping (Data.Element) -> Row)
        where Data.Element: Identifiable, Content == ForEach<Data, Data.Element.ID, Row> {
        self.init {
            ForEach(data, content: row)
        }
    }
}

/// A form on the background of the screens whose rows are drawn as surface.
struct PaperForm<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            Group {
                content
            }
            .surfaceRows()
        }
        .paperBackground()
    }
}
