import Foundation

/// The high-level state the menu-bar icon reflects.
nonisolated enum MonitorState: Equatable, Sendable, CaseIterable {
    /// The daemon is reachable and nothing is queued.
    case idle
    /// The daemon is reachable and a build holds the slot.
    case building
    /// Builds are waiting but the daemon is withholding the slot, which means an
    /// unauthorized build — typically a manual ⌘B in Xcode — is burning CPU.
    case blocked
    /// The daemon could not be reached (not running, or a network error).
    case offline

    /// Derive the display state from a fetched snapshot.
    ///
    /// The blocked case is an inference, but an exact one: the daemon advances
    /// the queue unless its probe sees a build already running, so a non-empty
    /// waiting line with no grant outstanding happens if and only if something
    /// outside the tower is building. A request reconciles the queue as it is
    /// enqueued, so this state cannot be observed before the probe has had its
    /// say.
    ///
    /// - Parameter snapshot: the latest snapshot, or `nil` if the fetch failed.
    static func derive(from snapshot: StatusDTO?) -> MonitorState {
        guard let snapshot else { return .offline }
        if snapshot.active != nil { return .building }
        return snapshot.waiting.isEmpty ? .idle : .blocked
    }

    /// The constant glyph identifying the app in the menu bar.
    ///
    /// Only its fill varies, so state is never conveyed by the anchor alone: as
    /// a monochrome template at menu-bar size, `hammer` and `hammer.fill` are
    /// near-indistinguishable. ``modifierSymbolName`` does the real work.
    var anchorSymbolName: String {
        self == .building ? "hammer.fill" : "hammer"
    }

    /// The glyph trailing the anchor, carrying the state.
    ///
    /// `nil` while building, where the numeric slot — progress or elapsed time —
    /// occupies that position instead.
    var modifierSymbolName: String? {
        switch self {
        case .idle: "zzz"
        case .building: nil
        case .blocked: "pause.circle"
        case .offline: "exclamationmark.triangle"
        }
    }

    /// A short human-readable name for accessibility and tooltips.
    var label: String {
        switch self {
        case .idle: "Idle"
        case .building: "Building"
        case .blocked: "Blocked"
        case .offline: "Offline"
        }
    }
}
