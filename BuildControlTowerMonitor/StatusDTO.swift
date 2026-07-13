import Foundation

/// The JSON payload returned by the daemon's `GET /status` endpoint.
///
/// Mirrors the daemon's `QueueSnapshot`. `active` is absent from the JSON when
/// no build holds the slot (the daemon encodes it with `encodeIfPresent`), so
/// it is decoded as an optional and a missing key becomes `nil` — the same as
/// an explicit `null`.
nonisolated struct StatusDTO: Decodable, Sendable, Equatable {
    /// One active or waiting build, as reported by the daemon.
    struct Entry: Decodable, Sendable, Equatable, Identifiable {
        /// The ticket id — a stable identity for SwiftUI list diffing.
        let id: UUID
        /// The optional agent label supplied when the build was requested.
        let agent: String?
    }

    /// The build currently holding the slot, or `nil` when idle.
    let active: Entry?

    /// Builds waiting for the slot, in FIFO order.
    let waiting: [Entry]

    /// The queue depth: the active build (if any) plus everyone waiting.
    var depth: Int {
        (active == nil ? 0 : 1) + waiting.count
    }
}
