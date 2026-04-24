import Foundation

struct MeetingSummary: Codable, Sendable, Equatable {
    var overview: String
    var keyTopics: [String]
    var actionItems: [String]
    var outcomeNote: String
}

struct PostMeetingSummaryService: Sendable {
    func generateSummary(for session: MeetingSessionRecord, documents: [IngestedDocument]) -> MeetingSummary {
        let transcriptTexts = session.transcriptSegments
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.text)

        let guidanceTexts = session.guidanceHistory
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.content.nowSay)

        let mergedText = (transcriptTexts + guidanceTexts).joined(separator: " ")
        let summaryText = summarize(mergedText, wordLimit: 34)

        let keyTopics = extractKeyTopics(from: transcriptTexts + guidanceTexts)
        let actionItems = buildActionItems(from: session, documents: documents)
        let outcomeNote = deriveOutcome(from: session, transcriptTexts: transcriptTexts)

        return MeetingSummary(
            overview: summaryText.isEmpty ? fallbackOverview(for: session) : summaryText,
            keyTopics: Array(keyTopics.prefix(4)),
            actionItems: Array(actionItems.prefix(4)),
            outcomeNote: outcomeNote
        )
    }

    private func extractKeyTopics(from texts: [String]) -> [String] {
        let interestingTokens = texts
            .flatMap { tokenize($0) }
            .filter { token in
                token.count > 4 && !stopWords.contains(token)
            }

        let ranked = Dictionary(interestingTokens.map { ($0, 1) }, uniquingKeysWith: +)
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .map(\.key)

        return ranked.map { $0.capitalized }
    }

    private func buildActionItems(from session: MeetingSessionRecord, documents: [IngestedDocument]) -> [String] {
        var items: [String] = []

        if let next = session.guidanceHistory.first?.content.next, !next.isEmpty {
            items.append(next)
        }

        if session.configuration.meetingType == "sales" {
            items.append("Follow up with the next concrete pilot or rollout step.")
        }

        if session.configuration.meetingType == "interview" {
            items.append("Prepare a sharper example for the topic that came up most.")
        }

        if !session.documentIDs.isEmpty {
            let attachedCount = documents.filter { session.documentIDs.contains($0.id) }.count
            items.append("Review the \(attachedCount) attached documents before the next meeting.")
        }

        if items.isEmpty {
            items.append("Review the meeting transcript and pick the next best follow-up.")
        }

        return deduplicated(items)
    }

    private func deriveOutcome(from session: MeetingSessionRecord, transcriptTexts: [String]) -> String {
        let transcript = transcriptTexts.joined(separator: " ").lowercased()
        if transcript.contains("pilot") || transcript.contains("next step") {
            return "The conversation pointed toward a concrete next-step discussion."
        }
        if transcript.contains("follow up") || transcript.contains("send") {
            return "A follow-up response or material handoff is likely needed."
        }
        if session.guidanceHistory.isEmpty {
            return "The session captured conversation context, but little guided output was recorded."
        }
        return "The session captured both conversation context and live guidance for later review."
    }

    private func fallbackOverview(for session: MeetingSessionRecord) -> String {
        "A \(session.configuration.meetingType) meeting with \(session.transcriptSegments.count) transcript items and \(session.guidanceHistory.count) guidance moments."
    }

    private func summarize(_ text: String, wordLimit: Int) -> String {
        text
            .split(whereSeparator: \.isWhitespace)
            .prefix(wordLimit)
            .joined(separator: " ")
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { value in
            seen.insert(value).inserted
        }
    }

    private let stopWords: Set<String> = [
        "about", "after", "again", "because", "before", "could", "there", "their",
        "would", "should", "while", "where", "which", "thanks", "based", "start",
        "still", "needs", "using", "local", "meeting", "answer", "clear", "first",
        "later", "right", "through"
    ]
}
