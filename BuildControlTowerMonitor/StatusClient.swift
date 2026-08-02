import Foundation

/// Errors surfaced by ``StatusClient``.
enum StatusClientError: Error, Equatable {
    /// The response was not an HTTP response, or carried a non-`200` status.
    case badStatus(code: Int)
}

/// A tiny async client for the daemon's read-only JSON endpoints: the queue
/// snapshot at `GET /status` and the timing policy at `GET /config`.
///
/// It uses an ephemeral, cache-disabled `URLSession`: `URLSession` will
/// otherwise cache a loopback `200` response, and the monitor would then freeze
/// on a stale snapshot instead of tracking the live queue.
nonisolated struct StatusClient: Sendable {
    /// The daemon base URL, e.g. `http://127.0.0.1:7373`.
    let baseURL: URL

    /// The session used for requests.
    let session: URLSession

    /// The queue-snapshot endpoint path appended to ``baseURL``.
    private static let statusPath = "status"

    /// The configuration endpoint path appended to ``baseURL``. Absent on
    /// daemons older than `0.3.0`, which answer `404`.
    private static let configPath = "config"

    /// A short per-request timeout so a hung daemon never stalls the UI.
    private static let requestTimeout: TimeInterval = 2

    /// Create a client. When `session` is omitted, a non-caching ephemeral
    /// session is built; pass a custom session (e.g. backed by a `URLProtocol`
    /// stub) in tests.
    init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            configuration.timeoutIntervalForRequest = Self.requestTimeout
            configuration.urlCache = nil
            self.session = URLSession(configuration: configuration)
        }
    }

    /// Fetch and decode the current queue snapshot.
    ///
    /// - Throws: ``StatusClientError/badStatus(code:)`` for a non-`200`
    ///   response, a `URLError` when the daemon is unreachable, or a decoding
    ///   error for a malformed body. The caller collapses any of these to an
    ///   "offline" state.
    func fetch() async throws -> StatusDTO {
        try await get(Self.statusPath)
    }

    /// Fetch and decode the daemon's timing policy.
    ///
    /// - Throws: the same errors as ``fetch()``. A `404` here means a daemon
    ///   predating the endpoint, so the caller keeps using
    ///   ``DaemonConfig/fallback`` rather than treating this as a fatal error —
    ///   the queue snapshot, not this call, is the liveness signal.
    func fetchConfig() async throws -> DaemonConfig {
        try await get(Self.configPath)
    }

    /// Issue a `GET` against a daemon path and decode the JSON body.
    private func get<Payload: Decodable>(_ path: String) async throws -> Payload {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.timeoutInterval = Self.requestTimeout
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StatusClientError.badStatus(code: -1)
        }
        guard http.statusCode == 200 else {
            throw StatusClientError.badStatus(code: http.statusCode)
        }
        return try JSONDecoder().decode(Payload.self, from: data)
    }
}
