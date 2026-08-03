import SwiftUI

/// Shows the configured control-tower repository path (or that none is set
/// yet) alongside a button to change it.
struct RepositoryPathRowView: View {
    /// The configured path, or `nil` if none has been chosen yet.
    let repoPath: URL?

    /// Called to clear the current path and re-prompt.
    let relocate: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Repository")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(repoPath?.path ?? "Not configured")
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            Button("Relocate…", action: relocate)
        }
    }
}
