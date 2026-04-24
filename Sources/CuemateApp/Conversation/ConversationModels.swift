import Foundation

struct ConversationRequest: Sendable {
    let configuration: MeetingConfiguration
    let transcriptSegments: [TranscriptSegment]
    let retrievalResults: [RetrievalSearchResult]
}

struct ConversationResponse: Sendable {
    let primary: String
    let why: String
    let next: String
    let modeLabel: String
}

struct ConversationResponsePayload: Codable {
    let primary: String
    let why: String
    let next: String
}
