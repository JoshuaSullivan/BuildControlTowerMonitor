import SwiftUI

/// An agent's label and the task it registered, rendered on one clipped line.
///
/// Both strings are agent-authored and the daemon applies no length limit,
/// validation, or sanitization, so they may be long or multi-line. They are
/// clipped rather than wrapped to keep the panel a predictable size.
struct BuildIdentityView: View {
    /// The agent's self-chosen label, if it supplied one.
    let agent: String?

    /// The short description of what is being built, if it supplied one.
    let task: String?

    var body: some View {
        HStack(spacing: 4) {
            Text(Self.displayName(agent))
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)

            if let task = Self.trimmed(task) {
                Text("— \(task)")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
    }

    /// The agent's label, falling back when it is absent or blank. An agent may
    /// register an empty string, which is not the same as having a name.
    private static func displayName(_ agent: String?) -> String {
        trimmed(agent) ?? "Unnamed agent"
    }

    /// The value with surrounding whitespace removed, or `nil` if nothing is
    /// left. Whitespace-only text should read as unlabeled, not as a label.
    private static func trimmed(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
