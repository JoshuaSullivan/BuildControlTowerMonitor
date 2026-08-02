import SwiftUI

/// One waiting build: its place in line, who is waiting for what, and how long
/// it has been queued.
///
/// Waiting entries carry no progress or check-in data — the daemon tracks those
/// only for whoever holds the slot.
struct WaitingBuildRowView: View {
    /// The 1-based position in the queue, taken from the FIFO array order the
    /// daemon publishes.
    let position: Int

    /// The waiting build.
    let entry: StatusDTO.WaitingEntry

    var body: some View {
        HStack(spacing: 6) {
            Text(position, format: .number)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(minWidth: 16, alignment: .trailing)

            BuildIdentityView(agent: entry.agent, task: entry.task)

            Text(entry.waitingSeconds.buildAgeDescription)
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
