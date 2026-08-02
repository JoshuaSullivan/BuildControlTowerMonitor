import SwiftUI

/// The active build: who is building what, how far along they say they are, how
/// long it has run, and how recently they checked in.
struct ActiveBuildRowView: View {
    /// The build holding the slot.
    let entry: StatusDTO.ActiveEntry

    /// How overdue this build's agent is for a check-in.
    let health: BuildHealth

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: health.symbolName)
                    .foregroundStyle(health.tint)
                    .accessibilityHidden(true)
                BuildIdentityView(agent: entry.agent, task: entry.task)
            }

            // The bar and its caption are siblings rather than the label slots of
            // a single ProgressView, so the caption's layout stays independent of
            // whether a bar is drawn at all.
            if let progress = entry.progress {
                ProgressView(value: Double(progress), total: 100)
                    .progressViewStyle(.linear)
            }

            HStack {
                if let progress = entry.progress {
                    Text(Double(progress) / 100, format: .percent.precision(.fractionLength(0)))
                } else {
                    // The daemon omits `progress` until an agent volunteers one,
                    // and many never do. Say so plainly rather than implying 0%.
                    Text("No estimate reported")
                }
                Spacer(minLength: 0)
                Text("\(entry.elapsedSeconds.buildAgeDescription) elapsed")
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)

            if health.warrantsExplanation {
                // Deliberately factual. A grant is reclaimed only when silence
                // passes the grace window *and* the daemon sees no build CPU, so
                // a quiet agent may well be building normally.
                Label(
                    "Last check-in \(entry.secondsSinceHeartbeat.buildAgeDescription) ago",
                    systemImage: "clock.badge.exclamationmark"
                )
                .font(.caption)
                .foregroundStyle(health.tint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
