import Foundation
import Observation
import OSLog

/// Observable state backing the menu-bar UI: the latest queue snapshot, the
/// derived display state, and the polling loop that keeps them fresh.
///
/// This target uses `MainActor` default actor isolation, so this `@Observable`
/// needs no explicit `@MainActor` annotation — it is main-actor isolated by
/// default, which is exactly what a SwiftUI-facing model wants.
@Observable
final class BuildStatusModel {
    /// The most recent snapshot, or `nil` when the daemon is unreachable.
    private(set) var snapshot: StatusDTO?

    /// The display state derived from ``snapshot``.
    private(set) var state: MonitorState = .offline

    /// The client used to fetch snapshots.
    private let client: StatusClient

    /// Steady-state polling cadence.
    private let interval: Duration

    /// Slower cadence used while offline, to avoid hammering a dead socket.
    private let offlineInterval: Duration

    /// Diagnostic log, useful for answering "why does it say offline?".
    private static let log = Logger(
        subsystem: "com.hairlessape.BuildControlTowerMonitor",
        category: "poll"
    )

    /// The queue depth (active + waiting); zero when offline.
    var depth: Int { snapshot?.depth ?? 0 }

    /// The active build, if any.
    var active: StatusDTO.Entry? { snapshot?.active }

    /// The waiting builds, in FIFO order.
    var waiting: [StatusDTO.Entry] { snapshot?.waiting ?? [] }

    /// Create a model.
    ///
    /// - Parameters:
    ///   - client: the snapshot source; defaults to one pointed at the resolved
    ///     daemon URL.
    ///   - interval: steady-state poll cadence (default 5s).
    ///   - offlineInterval: poll cadence while offline (default 15s).
    init(
        client: StatusClient = StatusClient(baseURL: MonitorConfiguration().baseURL),
        interval: Duration = .seconds(5),
        offlineInterval: Duration = .seconds(15)
    ) {
        self.client = client
        self.interval = interval
        self.offlineInterval = offlineInterval
    }

    /// Fetch once and update state. Any failure collapses to `.offline`.
    func refresh() async {
        let previous = state
        do {
            let snapshot = try await client.fetch()
            self.snapshot = snapshot
            self.state = .derive(from: snapshot)
        } catch {
            self.snapshot = nil
            self.state = .offline
        }
        if state != previous {
            Self.log.notice(
                "state \(previous.label, privacy: .public) → \(self.state.label, privacy: .public), depth \(self.depth, privacy: .public)"
            )
        }
    }

    /// Poll until cancelled, backing off while offline. Hosted by the always-
    /// present menu-bar label so it runs for the app's lifetime.
    func pollLoop() async {
        while !Task.isCancelled {
            await refresh()
            let delay = state == .offline ? offlineInterval : interval
            try? await Task.sleep(for: delay)
        }
    }
}
