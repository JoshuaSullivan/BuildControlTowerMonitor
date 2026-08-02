import Foundation

/// The timing policy the daemon reports from `GET /config`.
///
/// The queue's tuning is set per-install from the environment, so a monitor that
/// hardcodes the defaults silently disagrees with any daemon launched with
/// `BCT_GRACE_SECONDS` — flagging healthy builds as stale, or missing ones
/// genuinely at risk. Fetching the values lets ``BuildHealth`` judge against
/// what this daemon will actually do.
///
/// Every field is decoded leniently and falls back to ``fallback``: the endpoint
/// arrived in daemon `0.3.0`, and an older binary still running under launchd
/// answers `404`. The monitor must stay useful in that case.
nonisolated struct DaemonConfig: Decodable, Sendable, Equatable {
    /// The daemon's advertised version, when it reported one.
    let version: String?

    /// How often the daemon's background loop reconciles the queue.
    let pollSeconds: Int

    /// How long a grant may go silent, with no build CPU observed, before the
    /// daemon reclaims it. The upper bound on "quiet but legitimately building".
    let staleGrantGraceSeconds: Int

    /// The check-in cadence agents are asked to keep. Silence beyond this is the
    /// first sign an agent has stopped reporting, well before its grant is at
    /// risk.
    let recommendedHeartbeatSeconds: Int

    /// The daemon's documented defaults, used until `/config` answers and
    /// whenever it cannot be reached.
    static let fallback = DaemonConfig(
        version: nil,
        pollSeconds: 120,
        staleGrantGraceSeconds: 360,
        recommendedHeartbeatSeconds: 120
    )

    // Declared explicitly because the custom `init(from:)` suppresses synthesis.
    // The daemon also publishes `port` and `cpuThresholdPercent`; neither is
    // listed here because the monitor already knows the port it dialed and has
    // no use for the probe's threshold.
    enum CodingKeys: String, CodingKey {
        case version, pollSeconds, staleGrantGraceSeconds, recommendedHeartbeatSeconds
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        pollSeconds =
            try container.decodeIfPresent(Int.self, forKey: .pollSeconds)
            ?? Self.fallback.pollSeconds
        staleGrantGraceSeconds =
            try container.decodeIfPresent(Int.self, forKey: .staleGrantGraceSeconds)
            ?? Self.fallback.staleGrantGraceSeconds
        recommendedHeartbeatSeconds =
            try container.decodeIfPresent(Int.self, forKey: .recommendedHeartbeatSeconds)
            ?? Self.fallback.recommendedHeartbeatSeconds
    }
}

nonisolated extension DaemonConfig {
    /// Create a configuration directly, for tests and for ``fallback``.
    init(
        version: String?,
        pollSeconds: Int,
        staleGrantGraceSeconds: Int,
        recommendedHeartbeatSeconds: Int
    ) {
        self.version = version
        self.pollSeconds = pollSeconds
        self.staleGrantGraceSeconds = staleGrantGraceSeconds
        self.recommendedHeartbeatSeconds = recommendedHeartbeatSeconds
    }
}
