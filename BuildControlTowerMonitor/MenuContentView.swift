import SwiftUI
import AppKit

/// The window shown when the menu-bar item is clicked: the active build, the
/// waiting list, and a quit control. Live-updates as the model polls.
struct MenuContentView: View {
    /// The shared model, injected by the app.
    @Environment(BuildStatusModel.self) private var model

    /// Opens the app's auxiliary `Window` scenes (Daemon Control, About).
    @Environment(\.openWindow) private var openWindow

    /// Cap on the waiting list's height so a deep queue scrolls instead of
    /// growing the panel off the bottom of the screen.
    private static let waitingListMaxHeight: CGFloat = 160

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Build Control Tower")
                .font(.headline)

            switch model.state {
            case .offline:
                DaemonOfflineView()

            case .blocked:
                QueueBlockedView()

            case .idle, .building:
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let active = model.active, let health = model.activeHealth {
                        ActiveBuildRowView(entry: active, health: health)
                    } else {
                        Text("Idle — no active build")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !model.waiting.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Waiting (\(model.waiting.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(model.waiting.enumerated(), id: \.element.id) { index, entry in
                                WaitingBuildRowView(position: index + 1, entry: entry)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(maxHeight: Self.waitingListMaxHeight)
                }
            }

            Divider()

            Button("Daemon Control…", systemImage: "gearshape") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: WindowID.daemonControl)
            }

            Button("About", systemImage: "info.circle") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: WindowID.about)
            }

            Divider()

            Button("Quit Build Control Tower Monitor", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 320, alignment: .leading)
    }
}
