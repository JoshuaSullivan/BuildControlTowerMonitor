import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests that the DTO decodes exactly the JSON the daemon's `/status` endpoint
/// emits — including an absent `active` key when idle, and absent optionals for
/// anything the agent chose not to report.
struct StatusDTODecodingTests {
    private func decode(_ json: String) throws -> StatusDTO {
        try JSONDecoder().decode(StatusDTO.self, from: Data(json.utf8))
    }

    @Test func decodesIdleSnapshotWithAbsentActive() throws {
        // The daemon omits `active` entirely when nothing holds the slot.
        let dto = try decode(#"{"waiting":[]}"#)
        #expect(dto.active == nil)
        #expect(dto.waiting.isEmpty)
        #expect(dto.depth == 0)
    }

    @Test func decodesExplicitNullActive() throws {
        let dto = try decode(#"{"active":null,"waiting":[]}"#)
        #expect(dto.active == nil)
    }

    @Test func decodesTheDocumentedPayload() throws {
        let json = #"""
        {
          "active": {
            "id": "11111111-1111-1111-1111-111111111111",
            "agent": "claude-A",
            "task": "xcodebuild Teams iOS",
            "progress": 45,
            "elapsedSeconds": 90,
            "secondsSinceHeartbeat": 20
          },
          "waiting": [
            {
              "id": "22222222-2222-2222-2222-222222222222",
              "agent": "claude-B",
              "task": "swift test",
              "waitingSeconds": 240
            }
          ]
        }
        """#
        let dto = try decode(json)

        let active = try #require(dto.active)
        #expect(active.id == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        #expect(active.agent == "claude-A")
        #expect(active.task == "xcodebuild Teams iOS")
        #expect(active.progress == 45)
        #expect(active.elapsedSeconds == 90)
        #expect(active.secondsSinceHeartbeat == 20)

        #expect(dto.waiting.count == 1)
        #expect(dto.waiting[0].task == "swift test")
        #expect(dto.waiting[0].waitingSeconds == 240)
        #expect(dto.depth == 2)
    }

    @Test func absentProgressIsDistinctFromZero() throws {
        // The daemon omits `progress` until an agent reports one, and its own
        // tests pin that omission. "No estimate yet" must not read as "0% done".
        let noEstimate = try decode(#"""
        {"active":{"id":"11111111-1111-1111-1111-111111111111","elapsedSeconds":5,"secondsSinceHeartbeat":5},"waiting":[]}
        """#)
        let zero = try decode(#"""
        {"active":{"id":"11111111-1111-1111-1111-111111111111","progress":0,"elapsedSeconds":5,"secondsSinceHeartbeat":5},"waiting":[]}
        """#)

        #expect(noEstimate.active?.progress == nil)
        #expect(zero.active?.progress == 0)
    }

    @Test func decodesAbsentAgentAndTask() throws {
        // Both are optional on request_build, so an agent may supply neither.
        let dto = try decode(#"""
        {"active":null,"waiting":[{"id":"33333333-3333-3333-3333-333333333333","waitingSeconds":7}]}
        """#)

        #expect(dto.waiting[0].agent == nil)
        #expect(dto.waiting[0].task == nil)
    }

    @Test func agesDefaultToZeroOnAPreHeartbeatDaemon() throws {
        // launchd keeps the daemon alive across upgrades, so an older binary
        // lacking these fields can still be serving. Degrade to showing names
        // rather than failing to decode the payload at all.
        let dto = try decode(#"""
        {"active":{"id":"11111111-1111-1111-1111-111111111111","agent":"A"},
         "waiting":[{"id":"22222222-2222-2222-2222-222222222222","agent":"B"}]}
        """#)

        #expect(dto.active?.agent == "A")
        #expect(dto.active?.elapsedSeconds == 0)
        #expect(dto.active?.secondsSinceHeartbeat == 0)
        #expect(dto.waiting[0].waitingSeconds == 0)
        #expect(dto.depth == 2)
    }

    @Test func throwsOnMalformedJSON() {
        #expect(throws: (any Error).self) {
            _ = try decode("not json")
        }
    }
}
