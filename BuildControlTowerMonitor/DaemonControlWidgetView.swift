import SwiftUI

/// The daemon control widget: current availability, the four lifecycle
/// buttons, the GitHub update check, streamed action output, and the
/// repository path controls.
///
/// A real `Window`, not popover content — see `BuildControlTowerMonitorApp`
/// for why: a slow install must survive the user clicking elsewhere.
struct DaemonControlWidgetView: View {
    /// Supplies daemon HTTP-reachability and the running daemon's version.
    @Environment(BuildStatusModel.self) private var statusModel

    /// Owns install/start/stop/uninstall state, app-scoped.
    @Environment(DaemonControlModel.self) private var model

    /// Cadence for re-checking launchd registration while this window is open.
    private static let refreshInterval: Duration = .seconds(10)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daemon Control")
                .font(.headline)

            DaemonAvailabilityStatusView(availability: model.availability)

            DaemonActionButtonsView(model: model, httpReachable: httpReachable)

            UpdateAvailabilityView(availability: model.updateAvailability)

            if !model.outputLog.isEmpty {
                DaemonOutputLogView(lines: model.outputLog)
            }

            if let lastError = model.lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            RepositoryPathRowView(repoPath: model.repoPath, relocate: model.relocate)
        }
        .padding(16)
        .frame(width: 420, alignment: .leading)
        .task {
            await model.refreshAvailability(httpReachable: httpReachable)
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.refreshInterval)
                await model.refreshAvailability(httpReachable: httpReachable)
            }
        }
        .task {
            await model.checkForUpdates(localVersion: statusModel.config.version)
        }
    }

    /// Whether the daemon is answering HTTP, per the existing status poll.
    private var httpReachable: Bool {
        statusModel.state != .offline
    }
}
