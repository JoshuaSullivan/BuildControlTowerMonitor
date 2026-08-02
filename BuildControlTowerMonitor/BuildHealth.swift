import SwiftUI

/// How recently the active build's agent has checked in, judged against the
/// daemon's own thresholds rather than assumed ones.
///
/// This deliberately reports *reporting behaviour*, not liveness. The daemon
/// reclaims a grant only when silence passes the grace window **and** its CPU
/// probe sees no build running, so an agent that is quietly compiling keeps its
/// slot indefinitely. A silent build may be perfectly healthy; the monitor
/// cannot tell, and so must not claim otherwise.
nonisolated enum BuildHealth: Equatable, Sendable, CaseIterable {
    /// Checked in within the cadence the daemon asks agents to keep.
    case fresh
    /// Overdue for a check-in, but not yet near the reclaim window.
    case quiet
    /// Silent past the grace window. The daemon would reclaim the slot if its
    /// probe also saw no build CPU — which it may well see, so this is a
    /// prompt to look, not a verdict that anything is wrong.
    case stale

    /// Judge an active build's silence against the daemon's thresholds.
    ///
    /// - Parameters:
    ///   - secondsSinceHeartbeat: the age reported for the active entry.
    ///   - config: the thresholds this daemon is actually using.
    static func evaluate(secondsSinceHeartbeat: Int, config: DaemonConfig) -> BuildHealth {
        if secondsSinceHeartbeat >= config.staleGrantGraceSeconds { return .stale }
        if secondsSinceHeartbeat >= config.recommendedHeartbeatSeconds { return .quiet }
        return .fresh
    }

    /// The SF Symbol shown beside the active build.
    var symbolName: String {
        switch self {
        case .fresh: "circle.fill"
        case .quiet: "circle.righthalf.filled"
        case .stale: "exclamationmark.circle.fill"
        }
    }

    /// The tint for ``symbolName``. Colour is a secondary cue only — the symbol
    /// shape carries the same information for anyone who cannot distinguish it.
    var tint: Color {
        switch self {
        case .fresh: .green
        case .quiet: .yellow
        case .stale: .orange
        }
    }

    /// Whether the panel should spell out how long the agent has been silent.
    /// A build checking in on cadence needs no commentary.
    var warrantsExplanation: Bool { self != .fresh }
}
