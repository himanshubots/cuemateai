import Foundation

struct ConversationEngine: Sendable {
    func generate(request: ConversationRequest) -> ConversationResponse {
        let transcriptSummary = request.transcriptSegments
            .prefix(3)
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let retrievalContext = request.retrievalResults.first?.chunk.text ?? ""
        let tone = request.configuration.tone
        let length = request.configuration.length
        let userLevel = request.configuration.userLevel
        let meetingType = request.configuration.meetingType

        let opening = openingLine(tone: tone, meetingType: meetingType)
        let evidence = evidenceLine(from: retrievalContext, transcript: transcriptSummary, length: length)
        let primary = [opening, evidence]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let why = whyLine(userLevel: userLevel, retrievalResults: request.retrievalResults)
        let next = nextLine(meetingType: meetingType, transcript: transcriptSummary)

        return ConversationResponse(
            primary: primary.isEmpty ? fallbackPrimary(for: request.configuration) : primary,
            why: why,
            next: next,
            modeLabel: "Local heuristic engine"
        )
    }

    private func openingLine(tone: String, meetingType: String) -> String {
        switch (meetingType, tone) {
        case ("sales", "confident"):
            return "The strongest next step is to start with a focused pilot and expand once the team sees real value."
        case ("interview", _):
            return "A clear way to answer that is to connect your direct experience to the outcome they care about."
        case ("demo", _):
            return "The simplest way to frame this is around the workflow improvement the team will notice first."
        case (_, "technical"):
            return "The practical answer is to start with the system behavior, then explain the implementation tradeoff."
        default:
            return "A good response here is to keep the answer direct, practical, and easy to follow."
        }
    }

    private func evidenceLine(from retrievalContext: String, transcript: String, length: String) -> String {
        let trimmedContext = retrievalContext.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        let contextSentence: String
        if !trimmedContext.isEmpty {
            contextSentence = "Based on your material: \(summarize(trimmedContext, wordLimit: length == "short" ? 10 : length == "long" ? 28 : 18))."
        } else if !trimmedTranscript.isEmpty {
            contextSentence = "Based on what was just said: \(summarize(trimmedTranscript, wordLimit: length == "short" ? 10 : length == "long" ? 28 : 18))."
        } else {
            contextSentence = ""
        }

        return contextSentence
    }

    private func whyLine(userLevel: String, retrievalResults: [RetrievalSearchResult]) -> String {
        if let result = retrievalResults.first {
            if userLevel == "expert" {
                return "Anchors the answer in the highest-ranked local context from \(result.document.fileName) while staying concise."
            }
            return "Gives you a safe response grounded in your uploaded material so you do not have to improvise from scratch."
        }

        return userLevel == "expert"
            ? "Keeps the answer structured and fast even without document support."
            : "Keeps the answer clear and low-risk when context is still limited."
    }

    private func nextLine(meetingType: String, transcript: String) -> String {
        if transcript.lowercased().contains("price") || transcript.lowercased().contains("budget") {
            return "Ask what budget range or rollout size they are considering."
        }

        switch meetingType {
        case "sales":
            return "Ask what would need to be true for them to start a pilot."
        case "interview":
            return "Ask whether they want a deeper example or a shorter summary."
        case "demo":
            return "Ask which workflow they want to see next."
        default:
            return "Ask one focused follow-up to keep the conversation moving."
        }
    }

    private func fallbackPrimary(for configuration: MeetingConfiguration) -> String {
        switch configuration.userLevel {
        case "expert":
            return "Answer directly, tie it to the outcome, and keep one follow-up ready."
        default:
            return "Answer with one clear sentence first, then add a short supporting detail."
        }
    }

    private func summarize(_ text: String, wordLimit: Int) -> String {
        text
            .split(whereSeparator: \.isWhitespace)
            .prefix(wordLimit)
            .joined(separator: " ")
    }
}
