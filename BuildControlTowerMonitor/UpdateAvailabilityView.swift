import SwiftUI

/// The result of checking GitHub for a newer control-tower release than the
/// one the running daemon reports.
///
/// Silent for ``UpdateAvailability/unknown`` and
/// ``UpdateAvailability/localVersionUnavailable`` — a failed or inconclusive
/// check is never shown as an error, per the daemon control widget's design.
struct UpdateAvailabilityView: View {
    /// The check result to display.
    let availability: UpdateAvailability

    var body: some View {
        switch availability {
        case .upToDate:
            Label("Up to date", systemImage: "checkmark.seal")
                .foregroundStyle(.secondary)
        case .updateAvailable(let latest):
            Label("Update available: \(latest)", systemImage: "arrow.up.circle.fill")
                .foregroundStyle(.blue)
        case .unknown, .localVersionUnavailable:
            EmptyView()
        }
    }
}
