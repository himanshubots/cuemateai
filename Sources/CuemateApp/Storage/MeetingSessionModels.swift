import Foundation

struct GuidanceSnapshot: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let createdAt: Date
    let provider: String
    let retrievalQuery: String
    let sourceDocumentName: String?
    let content: OverlayContent
}

struct MeetingSessionRecord: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var title: String
    let startedAt: Date
    var endedAt: Date?
    var configuration: MeetingConfiguration
    var transcriptSegments: [TranscriptSegment]
    var guidanceHistory: [GuidanceSnapshot]
    var documentIDs: [UUID]
    var summary: MeetingSummary?
    var followUpNotes: String

    var isActive: Bool {
        endedAt == nil
    }
}

struct MeetingSessionLibrary: Codable, Sendable {
    var sessions: [MeetingSessionRecord]
}
