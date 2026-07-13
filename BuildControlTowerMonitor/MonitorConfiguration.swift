import Foundation

/// Resolves where the monitor should reach the Build Control Tower daemon.
///
/// The daemon binds to `127.0.0.1` on a port taken from its `BCT_PORT`
/// environment variable (default `7373`). A GUI app launched from Finder or at
/// login does not inherit the shell environment, so the port is resolved from,
/// in order of precedence:
///
/// 1. a `UserDefaults` integer override, and
/// 2. the process environment's `BCT_PORT`, then
/// 3. the built-in default (`7373`).
///
/// Set an override with:
///
/// ```sh
/// defaults write com.hairlessape.BuildControlTowerMonitor BCTPort 7399
/// ```
nonisolated struct MonitorConfiguration: Sendable {
    /// The loopback host the daemon always binds to.
    static let host = "127.0.0.1"

    /// The daemon's default port when nothing overrides it.
    static let defaultPort = 7373

    /// `UserDefaults` key holding an integer port override.
    static let portDefaultsKey = "BCTPort"

    /// The resolved port the monitor connects to.
    let port: Int

    /// The base URL of the daemon, e.g. `http://127.0.0.1:7373`.
    var baseURL: URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = Self.host
        components.port = port
        return components.url ?? Self.defaultBaseURL
    }

    /// Create a configuration for the given port, defaulting to the resolved
    /// port from the override chain.
    init(port: Int = MonitorConfiguration.resolvePort()) {
        self.port = port
    }

    /// Resolve the port from a `UserDefaults` override, then the environment,
    /// then the built-in default. Parameters are injectable for testing.
    static func resolvePort(
        defaults: UserDefaults = .standard,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> Int {
        if let override = defaults.object(forKey: portDefaultsKey) as? Int,
           validPortRange.contains(override) {
            return override
        }
        if let raw = environment["BCT_PORT"], let parsed = Int(raw),
           validPortRange.contains(parsed) {
            return parsed
        }
        return defaultPort
    }

    /// The range of valid TCP ports.
    private static let validPortRange = 1...65_535

    /// Loopback URL at the default port. The interpolated string is a valid URL
    /// literal, so the initializer never returns `nil`; used only as an
    /// unreachable fallback when `URLComponents` cannot form a URL.
    private static let defaultBaseURL = URL(string: "http://\(host):\(defaultPort)")!
}
