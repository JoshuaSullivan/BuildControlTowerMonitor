import Foundation

/// The high-level state the menu-bar icon reflects.
nonisolated enum MonitorState: Equatable, Sendable {
    /// The daemon is reachable and no build holds the slot.
    case idle
    /// The daemon is reachable and a build is active.
    case building
    /// The daemon could not be reached (not running, or a network error).
    case offline

    /// Derive the display state from a fetched snapshot.
    ///
    /// - Parameter snapshot: the latest snapshot, or `nil` if the fetch failed.
    static func derive(from snapshot: StatusDTO?) -> MonitorState {
        guard let snapshot else { return .offline }
        return snapshot.active == nil ? .idle : .building
    }

    /// The SF Symbol shown in the menu bar for this state.
    ///
    /// States are distinguished by *shape*, not color, because the menu bar
    /// renders symbols as monochrome templates.
    var symbolName: String {
        switch self {
        case .idle: "hammer"
        case .building: "hammer.fill"
        case .offline: "exclamationmark.triangle"
        }
    }

    /// A short human-readable name for accessibility and tooltips.
    var label: String {
        switch self {
        case .idle: "Idle"
        case .building: "Building"
        case .offline: "Offline"
        }
    }
}
