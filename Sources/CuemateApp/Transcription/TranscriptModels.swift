import Foundation

struct TranscriptSegment: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let speaker: String
    let text: String
    let confidence: Double
    let isFinal: Bool
    let createdAt: Date
}

enum TranscriptionState: String, Sendable {
    case idle
    case requestingPermission
    case ready
    case listening
    case denied
    case unavailable
    case failed
}
