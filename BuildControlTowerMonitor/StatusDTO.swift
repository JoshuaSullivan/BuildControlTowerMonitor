import Foundation

/// The JSON payload returned by the daemon's `GET /status` endpoint.
///
/// Mirrors the daemon's `QueueSnapshot`. The daemon encodes optionals with
/// `encodeIfPresent`, so an absent value is a *missing key* rather than an
/// explicit `null` — both decode to `nil` here.
///
/// All ages arrive as plain second counts measured against the daemon's
/// monotonic clock, not as timestamps. They are therefore meaningful only
/// relative to the moment the snapshot was taken, and are not comparable across
/// a daemon restart, which resets the clock and clears the queue entirely.
nonisolated struct StatusDTO: Decodable, Sendable, Equatable {
    /// The build holding the slot, including whatever it has reported about its
    /// own progress.
    struct ActiveEntry: Decodable, Sendable, Equatable, Identifiable {
        /// The ticket id — a stable identity for SwiftUI list diffing, and the
        /// signal that the slot changed hands when it differs between polls.
        let id: UUID

        /// The optional agent label supplied when the build was requested.
        let agent: String?

        /// The optional short description of what is being built.
        let task: String?

        /// The agent's own completion estimate, `0...100`.
        ///
        /// `nil` means *no estimate reported*, which is distinct from `0`. It is
        /// a self-report, so it is not necessarily monotonic, and it reverts to
        /// `nil` when the slot passes to a new agent.
        let progress: Int?

        /// Seconds since the slot was granted.
        ///
        /// Always present, which makes it the reliable fallback for a UI that
        /// wants to say *something* about a build that never reported progress.
        let elapsedSeconds: Int

        /// Seconds since the agent last showed a sign of life.
        ///
        /// Despite the daemon's field name this is the *last check-in*, not
        /// strictly the last heartbeat: the grant itself, any `build_heartbeat`,
        /// and any `build_status` poll all refresh it.
        let secondsSinceHeartbeat: Int

        // Declared explicitly because the custom `init(from:)` below suppresses
        // synthesis.
        enum CodingKeys: String, CodingKey {
            case id, agent, task, progress, elapsedSeconds, secondsSinceHeartbeat
        }
    }

    /// One build waiting for the slot. Waiting entries carry no progress or
    /// check-in data — the daemon tracks those only for the grantee.
    struct WaitingEntry: Decodable, Sendable, Equatable, Identifiable {
        /// The ticket id — a stable identity for SwiftUI list diffing.
        let id: UUID

        /// The optional agent label supplied when the build was requested.
        let agent: String?

        /// The optional short description of what is being built.
        let task: String?

        /// Seconds this request has been in the queue.
        let waitingSeconds: Int

        enum CodingKeys: String, CodingKey {
            case id, agent, task, waitingSeconds
        }
    }

    /// The build currently holding the slot, or `nil` when idle.
    let active: ActiveEntry?

    /// Builds waiting for the slot, in FIFO order. Position is implicit in the
    /// array order; the daemon publishes no position field.
    let waiting: [WaitingEntry]

    /// The queue depth: the active build (if any) plus everyone waiting.
    var depth: Int {
        (active == nil ? 0 : 1) + waiting.count
    }
}

// MARK: - Tolerant decoding

// The age fields arrived with the daemon's heartbeat release. `install.sh`
// bootstraps the daemon under launchd with `KeepAlive`, so an older binary can
// plausibly still be serving; defaulting the counts lets the monitor degrade to
// showing names rather than failing to decode the payload at all. Declaring
// these in extensions keeps the synthesized memberwise initializers available.

nonisolated extension StatusDTO.ActiveEntry {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        agent = try container.decodeIfPresent(String.self, forKey: .agent)
        task = try container.decodeIfPresent(String.self, forKey: .task)
        progress = try container.decodeIfPresent(Int.self, forKey: .progress)
        elapsedSeconds = try container.decodeIfPresent(Int.self, forKey: .elapsedSeconds) ?? 0
        secondsSinceHeartbeat = try container.decodeIfPresent(Int.self, forKey: .secondsSinceHeartbeat) ?? 0
    }
}

nonisolated extension StatusDTO.WaitingEntry {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        agent = try container.decodeIfPresent(String.self, forKey: .agent)
        task = try container.decodeIfPresent(String.self, forKey: .task)
        waitingSeconds = try container.decodeIfPresent(Int.self, forKey: .waitingSeconds) ?? 0
    }
}
