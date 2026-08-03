import SwiftUI

/// The four daemon lifecycle buttons, enabled according to the current
/// ``DaemonAvailability`` and whether an action is already in flight.
///
/// Install/Reinstall stays enabled in every state (including before a
/// repository is configured — ``DaemonControlModel/perform(_:httpReachable:)``
/// prompts for one on first use), since `build.sh --install-agent` is
/// idempotent and doubles as the upgrade path.
struct DaemonActionButtonsView: View {
    /// The model actions are dispatched to.
    let model: DaemonControlModel

    /// `BuildStatusModel.state != .offline`, read at the call site so this
    /// view doesn't need its own daemon-reachability logic.
    let httpReachable: Bool

    /// Off by default: running the daemon's real test suite before
    /// installing a binary is the correct default, not a slower opt-out.
    @State private var skipTestsOnInstall = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Skip tests (faster)", isOn: $skipTestsOnInstall)
                .toggleStyle(.checkbox)
                .disabled(model.inFlightAction != nil)

            HStack(spacing: 8) {
                Button(installTitle, systemImage: "arrow.down.circle") {
                    dispatch(.install(skipTests: skipTestsOnInstall))
                }
                .disabled(model.inFlightAction != nil)

                Button("Uninstall", systemImage: "trash") {
                    dispatch(.uninstall)
                }
                .disabled(!canUninstall)

                Button("Start", systemImage: "play.circle") {
                    dispatch(.start)
                }
                .disabled(!canStart)

                Button("Stop", systemImage: "stop.circle") {
                    dispatch(.stop)
                }
                .disabled(!canStop)
            }
        }
    }

    private var installTitle: String {
        model.availability == .notInstalled ? "Install" : "Reinstall"
    }

    private var canUninstall: Bool {
        model.inFlightAction == nil
            && model.availability != .notInstalled
            && model.availability != .unknown
    }

    private var canStart: Bool {
        model.inFlightAction == nil && model.availability == .installedStopped
    }

    private var canStop: Bool {
        model.inFlightAction == nil && model.availability == .installedRunning
    }

    private func dispatch(_ action: DaemonAction) {
        Task { await model.perform(action, httpReachable: httpReachable) }
    }
}
