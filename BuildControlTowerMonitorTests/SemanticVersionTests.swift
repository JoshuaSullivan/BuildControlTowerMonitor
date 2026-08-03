import Testing
@testable import BuildControlTowerMonitor

/// Tests parsing and comparison of the minimal `major.minor.patch` version.
struct SemanticVersionTests {
    @Test func parsesFullVersion() {
        let version = SemanticVersion(parsing: "1.2.3")
        #expect(version?.major == 1)
        #expect(version?.minor == 2)
        #expect(version?.patch == 3)
    }

    @Test func stripsLeadingV() {
        #expect(SemanticVersion(parsing: "v1.2.3") == SemanticVersion(parsing: "1.2.3"))
    }

    @Test func defaultsMissingComponentsToZero() {
        let minorOnly = SemanticVersion(parsing: "1.2")
        #expect(minorOnly?.patch == 0)
        let majorOnly = SemanticVersion(parsing: "1")
        #expect(majorOnly?.minor == 0)
        #expect(majorOnly?.patch == 0)
    }

    @Test func rejectsInvalidStrings() {
        #expect(SemanticVersion(parsing: "abc") == nil)
        #expect(SemanticVersion(parsing: "") == nil)
        #expect(SemanticVersion(parsing: "1.2.3.4") == nil)
    }

    @Test func comparesNumericallyNotLexicographically() throws {
        let older = try #require(SemanticVersion(parsing: "1.9.0"))
        let newer = try #require(SemanticVersion(parsing: "1.10.0"))
        #expect(older < newer)
    }

    @Test func comparesAcrossMajorAndMinor() throws {
        let v123 = try #require(SemanticVersion(parsing: "1.2.3"))
        let v200 = try #require(SemanticVersion(parsing: "2.0.0"))
        #expect(v123 < v200)
        #expect(v123 == v123)
    }
}
