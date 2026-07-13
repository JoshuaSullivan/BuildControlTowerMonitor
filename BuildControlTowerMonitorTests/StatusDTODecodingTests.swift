import Foundation
import Testing
@testable import BuildControlTowerMonitor

/// Tests that the DTO decodes exactly the JSON the daemon's `/status` endpoint
/// emits — including an absent `active` key when idle.
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

    @Test func decodesActiveAndWaitingWithNullAgent() throws {
        let json = #"""
        {
          "active": { "id": "11111111-1111-1111-1111-111111111111", "agent": "A" },
          "waiting": [
            { "id": "22222222-2222-2222-2222-222222222222", "agent": "B" },
            { "id": "33333333-3333-3333-3333-333333333333", "agent": null }
          ]
        }
        """#
        let dto = try decode(json)
        #expect(dto.active?.agent == "A")
        #expect(dto.active?.id == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        #expect(dto.waiting.count == 2)
        #expect(dto.waiting[1].agent == nil)
        #expect(dto.depth == 3)
    }

    @Test func throwsOnMalformedJSON() {
        #expect(throws: (any Error).self) {
            _ = try decode("not json")
        }
    }
}
