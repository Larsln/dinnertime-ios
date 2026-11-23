import DinnertimeKit
import SwiftUI

/// Why a meal goes with the rest of the plan, one short line per reason; what it shares with other meals comes first.
struct PlanReasonList: View {
    let reasons: [PlanReason]
    /// The most lines a single reason may take.
    var lineLimit = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(reasons.enumerated()), id: \.offset) { _, reason in
                if let text = reason.text {
                    Label {
                        Text(verbatim: text)
                            .lineLimit(lineLimit)
                    } icon: {
                        Image(systemName: reason.systemImage)
                            .foregroundStyle(reason.isAboutTheWeek ? Color.accentDeep : Color.inkMuted)
                    }
                    .font(.caption)
                    .foregroundStyle(.inkMuted)
                }
            }
        }
        .labelStyle(.titleAndIcon)
        .multilineTextAlignment(.leading)
    }
}
