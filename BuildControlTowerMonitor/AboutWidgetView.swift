import SwiftUI

/// Copyright/author attribution and links to both projects' GitHub repos.
struct AboutWidgetView: View {
    private static let monitorRepoURL = URL(string: "https://github.com/JoshuaSullivan/BuildControlTowerMonitor")!
    private static let controlTowerRepoURL = URL(string: "https://github.com/JoshuaSullivan/build-control-tower")!

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "hammer.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            VStack(spacing: 2) {
                Text("Build Control Tower Monitor")
                    .font(.headline)
                Text("Version \(version)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("© 2026 Josh Sullivan")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Link("BuildControlTowerMonitor on GitHub", destination: Self.monitorRepoURL)
                Link("build-control-tower on GitHub", destination: Self.controlTowerRepoURL)
            }
        }
        .padding(24)
        .frame(width: 340)
    }

    /// The Monitor's own marketing version, e.g. `"0.1.0"`.
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}
