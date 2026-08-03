import SwiftUI

/// A status line reflecting whether the daemon is installed and running.
struct DaemonAvailabilityStatusView: View {
    /// The availability to display.
    let availability: DaemonAvailability

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(text, systemImage: symbolName)
                .foregroundStyle(tint)
            if availability == .unknown {
                Text("Could not determine daemon status — is launchctl available?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var text: String {
        switch availability {
        case .notInstalled: "Not installed"
        case .installedStopped: "Installed, stopped"
        case .installedRunning: "Installed, running"
        case .unknown: "Status unknown"
        }
    }

    private var symbolName: String {
        switch availability {
        case .notInstalled: "circle.dashed"
        case .installedStopped: "pause.circle"
        case .installedRunning: "checkmark.circle.fill"
        case .unknown: "questionmark.circle"
        }
    }

    private var tint: Color {
        switch availability {
        case .notInstalled: .secondary
        case .installedStopped: .orange
        case .installedRunning: .green
        case .unknown: .red
        }
    }
}
