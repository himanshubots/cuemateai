import Foundation

struct OpenAIGenerationRequest: Sendable {
    let apiKey: String
    let model: String
    let outputMode: OpenAIOutputMode
    let request: ConversationRequest
}

enum OpenAIConversationError: LocalizedError {
    case invalidURL
    case badStatus(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "OpenAI URL is invalid"
        case .badStatus(let status, let body):
            return "OpenAI request failed with status \(status): \(body)"
        case .invalidResponse:
            return "OpenAI response could not be decoded"
        }
    }
}

struct OpenAIConversationService: Sendable {
    private let modeHelper = MeetingModePromptHelper()

    func generate(from input: OpenAIGenerationRequest) async throws -> ConversationResponse {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw OpenAIConversationError.invalidURL
        }

        let prompt = buildPrompt(from: input.request)
        let body = ChatCompletionsRequest(
            model: input.model,
            messages: [
                ChatMessage(role: "system", content: systemInstruction),
                ChatMessage(role: "user", content: prompt)
            ],
            responseFormat: ResponseFormat(type: "json_object")
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(input.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OpenAIConversationError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIConversationError.badStatus(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionsResponse.self, from: data)
        guard
            let content = decoded.choices.first?.message.content,
            let payload = try? JSONDecoder().decode(ConversationResponsePayload.self, from: Data(content.utf8))
        else {
            throw OpenAIConversationError.invalidResponse
        }

        return ConversationResponse(
            primary: payload.primary,
            why: payload.why,
            next: payload.next,
            modeLabel: "OpenAI \(input.model) \(input.outputMode.title)"
        )
    }

    private func buildPrompt(from request: ConversationRequest) -> String {
        let you = request.userDisplayName
        let other = request.collaboratorRoleLabel
        let modeGuidance = modeHelper.systemPromptSection(for: request.configuration.meetingType, intent: request.detectedIntent)
        let participantContext = modeHelper.participantContextLine(for: request.configuration)
        let goalsSection = modeHelper.meetingGoalsSection(for: request.configuration)
        let memorySection = request.crossSessionMemory

        let latestQ = request.latestQuestion.map { seg in
            let prefix = request.sharedTranscriptMode ? "Mixed room transcript" : other
            return "\(prefix): \(seg.text.trimmingCharacters(in: .whitespacesAndNewlines))"
        } ?? "None"

        let priorTurns = request.transcriptSegments.filter { seg in
            seg.id != request.latestQuestion?.id
        }.prefix(3).map { seg in
            if request.sharedTranscriptMode {
                return seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let label = seg.speaker.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                == you.lowercased() ? you : other
            return "\(label): \(seg.text.trimmingCharacters(in: .whitespacesAndNewlines))"
        }.joined(separator: "\n")

        let sources = request.retrievalResults.prefix(2).map { result in
            "[\(result.document.fileName)] \(result.chunk.text)"
        }.joined(separator: "\n")

        let participantLine = participantContext.isEmpty ? "\(other) (unknown contact)" : "\(other): \(participantContext)"

        let langLine: String = {
            let lang = MeetingLanguage(rawValue: request.meetingLanguage) ?? .english
            if lang == .autoDetect || lang == .english { return "" }
            return "Meeting language: \(lang.title). Respond in \(lang.title)."
        }()

        var parts = [
            "Return only the exact short answer the user should say next.",
            "Do not add coaching language, stage directions, or meta commentary.",
            "Keep the primary answer to 1-2 short sentences. Prefer clarity over completeness.",
            "",
            "Participants: \(you) (user) | \(participantLine)",
            "Meeting type: \(request.configuration.meetingType) | tone: \(request.configuration.tone) | length: \(request.configuration.length) | level: \(request.configuration.userLevel)",
        ]
        if request.sharedTranscriptMode {
            parts.append("Transcript mode: mixed room audio from a single device. Speaker labels are unreliable, so infer the latest actionable ask from context and ignore filler or likely echoed answer fragments.")
        }
        if !langLine.isEmpty { parts.append(langLine) }
        if !goalsSection.isEmpty { parts.append(""); parts.append(goalsSection) }
        if !memorySection.isEmpty { parts.append(""); parts.append(memorySection) }
        let screenSection = request.screenContext.trimmingCharacters(in: .whitespacesAndNewlines)

        parts += [
            "",
            "Latest statement/question to respond to:",
            latestQ,
            "",
            "Prior context (recent turns):",
            priorTurns.isEmpty ? "None" : priorTurns,
            "",
            "Retrieved knowledge:",
            sources.isEmpty ? "None" : sources,
        ]
        if !screenSection.isEmpty {
            parts += [
                "",
                "Visible on screen (slide or shared content — for additional context only):",
                String(screenSection.prefix(1500)),
            ]
        }
        let calSection = request.calendarContext.trimmingCharacters(in: .whitespacesAndNewlines)
        if !calSection.isEmpty {
            parts += ["", "Calendar event context:", calSection]
        }
        let teamSection = request.teamContext.trimmingCharacters(in: .whitespacesAndNewlines)
        if !teamSection.isEmpty {
            parts += ["", "Team context (always apply):", teamSection]
        }
        parts += [
            "",
            modeGuidance,
            "",
            "Return JSON with keys primary, why, next. Keep why and next empty unless they are truly necessary.",
        ]
        return parts.joined(separator: "\n")
    }

    private var systemInstruction: String {
        """
        You are generating the exact next words the user should say aloud.
        The primary field must be direct answer text, not advice about how to answer.
        Avoid phrases like "a clear way to answer" or "you can say."
        Return strict JSON:
        {"primary":"...","why":"...","next":"..."}
        """
    }
}

private struct ChatCompletionsRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case responseFormat = "response_format"
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionsResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: ChatMessage
    }
}

private struct ResponseFormat: Codable {
    let type: String
}
