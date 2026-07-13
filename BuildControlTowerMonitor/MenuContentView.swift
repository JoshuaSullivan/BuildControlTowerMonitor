import SwiftUI
import AppKit

/// The window shown when the menu-bar item is clicked: the active build, the
/// waiting list, and a quit control. Live-updates as the model polls.
struct MenuContentView: View {
    /// The shared model, injected by the app.
    @Environment(BuildStatusModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Build Control Tower")
                .font(.headline)

            switch model.state {
            case .offline:
                VStack(alignment: .leading, spacing: 4) {
                    Label("Daemon offline", systemImage: "exclamationmark.triangle")
                    Text("Is Build Control Tower running?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            case .idle, .building:
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let active = model.active {
                        BuildRowView(position: nil, entry: active)
                    } else {
                        Text("Idle — no active build")
                            .foregroundStyle(.secondary)
                    }
                }

                if !model.waiting.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Waiting (\(model.waiting.count))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(model.waiting.enumerated(), id: \.element.id) { index, entry in
                            BuildRowView(position: index + 1, entry: entry)
                        }
                    }
                }
            }

            Divider()

            Button("Quit Build Control Tower Monitor", systemImage: "power") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 280, alignment: .leading)
    }
}
