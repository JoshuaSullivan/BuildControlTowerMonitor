import SwiftUI

/// Shown when builds are queued but the daemon is granting nothing.
///
/// The daemon withholds the slot while its probe sees a build already burning
/// CPU that the tower did not authorize — in practice a manual build started in
/// Xcode. Naming the likely cause turns an inexplicable stall into an obvious
/// one, since the queue will clear itself the moment that build finishes.
struct QueueBlockedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Queue held — no slot granted", systemImage: "pause.circle")
            Text("A build the tower didn't start is using the CPU, likely a manual build in Xcode. The queue resumes on its own once it finishes.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
