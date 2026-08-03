import Foundation

/// Whether a newer control-tower release is available than the one currently
/// running.
nonisolated enum UpdateAvailability: Sendable, Equatable {
    /// The running daemon is at or ahead of the latest published release.
    case upToDate
    /// A newer release is published; carries its tag for display.
    case updateAvailable(latest: String)
    /// The GitHub check failed (offline, rate-limited, malformed response) —
    /// never treated as an error, just "can't tell right now".
    case unknown
    /// The daemon didn't report a version (predates `/config`, or is offline).
    case localVersionUnavailable
}

/// Compares the daemon's self-reported version against the latest tag
/// published on GitHub. Pure and network-free — ``ControlTowerReleaseClient``
/// does the fetching, this just judges the result.
nonisolated enum UpdateChecker {
    /// - Parameters:
    ///   - localVersion: ``DaemonConfig/version``, the running daemon's
    ///     self-reported version.
    ///   - remoteTag: the tag fetched from GitHub, or `nil` if that fetch
    ///     failed.
    static func evaluate(localVersion: String?, remoteTag: String?) -> UpdateAvailability {
        guard let localVersion, let local = SemanticVersion(parsing: localVersion) else {
            return .localVersionUnavailable
        }
        guard let remoteTag, let remote = SemanticVersion(parsing: remoteTag) else {
            return .unknown
        }
        return local < remote ? .updateAvailable(latest: remoteTag) : .upToDate
    }
}
