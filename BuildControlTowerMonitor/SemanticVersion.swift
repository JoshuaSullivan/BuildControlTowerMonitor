import Foundation

/// A minimal `major.minor.patch` version, comparable numerically rather than
/// lexicographically (so `1.10.0 > 1.9.0`).
///
/// Deliberately not a general semver implementation (no prerelease/build
/// metadata) — the project avoids third-party dependencies, and comparing the
/// control tower's `X.Y.Z` release tags needs nothing more than this.
nonisolated struct SemanticVersion: Sendable, Equatable, Comparable {
    let major: Int
    let minor: Int
    let patch: Int

    /// Parse a version string such as `"1.2.3"` or `"v1.2.3"`. Missing
    /// trailing components default to `0` (`"1.2"` → `1.2.0`, `"1"` → `1.0.0`).
    /// Returns `nil` for anything that isn't a leading-`v`-optional,
    /// dot-separated run of non-negative integers.
    init?(parsing string: String) {
        var trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("v") || trimmed.hasPrefix("V") {
            trimmed.removeFirst()
        }
        let components = trimmed.split(separator: ".", omittingEmptySubsequences: false)
        guard !components.isEmpty, components.count <= 3 else { return nil }
        let numbers = components.compactMap { Int($0) }
        guard numbers.count == components.count else { return nil }
        major = numbers[0]
        minor = numbers.count > 1 ? numbers[1] : 0
        patch = numbers.count > 2 ? numbers[2] : 0
    }

    private init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
