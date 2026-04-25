import Foundation

// MARK: - Request

/// Input for AI-backed pre-meeting brief generation via Ollama.
/// Pass the pre-computed heuristic document highlights so the LLM can reference them
/// without needing to re-scan raw chunks.
struct OllamaBriefGenerationRequest: Sendable {
    let model: String
    let configuration: MeetingConfiguration
    /// Heuristic document highlights already extracted by MeetingBriefBuilder.
    /// Passed to the prompt so the LLM can build on them.
    let documentHighlights: [MeetingBrief.DocumentHighlight]
    /// Note from the most recent prior session of the same type, if any.
    let priorSessionNote: String?
}

// MARK: - Error

enum OllamaBriefError: LocalizedError {
    case invalidURL
    case badStatus(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ollama URL is invalid"
        case .badStatus(let code, let body):
            return "Ollama brief request failed with status \(code): \(body)"
        case .invalidResponse:
            return "Ollama brief response could not be decoded"
        }
    }
}

// MARK: - Service

/// Generates a `MeetingBrief` by posting to a local Ollama instance.
/// Uses `MeetingModePromptHelper.preMeetingPromptSection` as the shared prompt surface.
/// Merges the LLM payload with the pre-computed heuristic doc highlights.
struct OllamaBriefService: Sendable {
    private let modeHelper = MeetingModePromptHelper()

    func generateBrief(from input: OllamaBriefGenerationRequest) async throws -> MeetingBrief {
        guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else {
            throw OllamaBriefError.invalidURL
        }

        let body = OllamaBriefAPIRequest(
            model: input.model,
            prompt: buildPrompt(from: input),
            format: briefJSONSchema,
            stream: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OllamaBriefError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OllamaBriefError.badStatus(http.statusCode, body)
        }

        let raw = try JSONDecoder().decode(OllamaBriefAPIResponse.self, from: data)
        guard
            let payloadData = raw.response.data(using: .utf8),
            let payload = try? JSONDecoder().decode(OllamaBriefPayload.self, from: payloadData)
        else {
            throw OllamaBriefError.invalidResponse
        }

        return assembleBrief(from: payload, input: input)
    }

    // MARK: - Prompt

    private func buildPrompt(from input: OllamaBriefGenerationRequest) -> String {
        let modeSection = modeHelper.preMeetingPromptSection(
            for: input.configuration.meetingType,
            hasDocs: !input.documentHighlights.isEmpty,
            hasPriorSession: input.priorSessionNote != nil
        )

        var parts: [String] = [
            "You are a meeting preparation assistant. Produce a concise, practical pre-meeting brief.",
            "Keep each field short and actionable. Avoid filler.",
            "",
            modeSection,
        ]

        if let note = input.priorSessionNote, !note.isEmpty {
            parts.append("")
            parts.append("Prior session context: \(note)")
        }

        if !input.documentHighlights.isEmpty {
            parts.append("")
            parts.append("Document highlights:")
            for highlight in input.documentHighlights {
                parts.append("- [\(highlight.documentName)] \(highlight.relevantExcerpt)")
            }
        }

        parts.append("")
        parts.append("Return strict JSON with these keys:")
        parts.append("- meetingGoal: one sentence stating the primary session goal")
        parts.append("- focusAreas: array of 3–5 short strings naming areas to watch or drive")
        parts.append("- likelyRisks: array of 2–3 short strings naming objections or risks to anticipate")
        parts.append("- suggestedNextStep: one sentence on how to close the meeting toward a next step")
        parts.append("- openingFraming: one sentence on how to open the meeting with intent")
        parts.append("- priorSessionNote: a short sentence referencing prior session context, or empty string if none")

        return parts.joined(separator: "\n")
    }

    // MARK: - Assembly

    private func assembleBrief(
        from payload: OllamaBriefPayload,
        input: OllamaBriefGenerationRequest
    ) -> MeetingBrief {
        MeetingBrief(
            meetingType: input.configuration.meetingType,
            meetingGoal: payload.meetingGoal.isEmpty
                ? fallbackGoal(for: input.configuration.meetingType)
                : payload.meetingGoal,
            focusAreas: payload.focusAreas.isEmpty
                ? modeHelper.summaryFocusAreas(for: input.configuration.meetingType)
                : payload.focusAreas,
            likelyRisks: payload.likelyRisks.isEmpty
                ? fallbackRisks(for: input.configuration.meetingType)
                : payload.likelyRisks,
            suggestedNextStep: payload.suggestedNextStep,
            openingFraming: payload.openingFraming,
            // Heuristic document highlights are passed through — LLM doesn't produce them
            documentHighlights: input.documentHighlights,
            priorSessionNote: payload.priorSessionNote.isEmpty ? input.priorSessionNote : payload.priorSessionNote,
            generatedAt: Date()
        )
    }

    // MARK: - Fallbacks (used if LLM returns empty fields)

    private func fallbackGoal(for meetingType: String) -> String {
        modeHelper.coachingObjective(for: meetingType)
    }

    private func fallbackRisks(for meetingType: String) -> [String] {
        switch meetingType {
        case "sales":         return ["Budget or procurement gating.", "Decision-maker absent.", "Timeline misalignment."]
        case "demo":          return ["Workflow mismatch.", "Integration objection.", "Unprepared use case."]
        case "client-review": return ["Invisible progress.", "Undiscussed risk.", "Scope drift."]
        case "interview":     return ["Unprepared example.", "Narrower requirements.", "Experience gap."]
        case "internal-sync": return ["Stalled decision.", "Unclear ownership.", "External dependencies."]
        default:              return ["Goal drift.", "Decision not reached."]
        }
    }

    // MARK: - JSON schema

    private var briefJSONSchema: OllamaBriefSchema {
        OllamaBriefSchema(
            type: "object",
            properties: [
                "meetingGoal":      OllamaBriefProperty(type: "string"),
                "focusAreas":       OllamaBriefProperty(type: "array", items: OllamaBriefItems(type: "string")),
                "likelyRisks":      OllamaBriefProperty(type: "array", items: OllamaBriefItems(type: "string")),
                "suggestedNextStep": OllamaBriefProperty(type: "string"),
                "openingFraming":   OllamaBriefProperty(type: "string"),
                "priorSessionNote": OllamaBriefProperty(type: "string"),
            ],
            required: [
                "meetingGoal", "focusAreas", "likelyRisks",
                "suggestedNextStep", "openingFraming", "priorSessionNote",
            ]
        )
    }
}

// MARK: - Private wire types

private struct OllamaBriefAPIRequest: Codable {
    let model: String
    let prompt: String
    let format: OllamaBriefSchema
    let stream: Bool
}

private struct OllamaBriefAPIResponse: Codable {
    let response: String
}

private struct OllamaBriefPayload: Codable {
    let meetingGoal: String
    let focusAreas: [String]
    let likelyRisks: [String]
    let suggestedNextStep: String
    let openingFraming: String
    let priorSessionNote: String
}

private struct OllamaBriefSchema: Codable {
    let type: String
    let properties: [String: OllamaBriefProperty]
    let required: [String]
}

private struct OllamaBriefProperty: Codable {
    let type: String
    let items: OllamaBriefItems?

    init(type: String, items: OllamaBriefItems? = nil) {
        self.type = type
        self.items = items
    }
}

private struct OllamaBriefItems: Codable {
    let type: String
}
