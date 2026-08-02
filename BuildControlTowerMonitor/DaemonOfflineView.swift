import SwiftUI

/// Shown when the daemon cannot be reached at all.
struct DaemonOfflineView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Daemon offline", systemImage: "exclamationmark.triangle")
            Text("Is Build Control Tower running?")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
