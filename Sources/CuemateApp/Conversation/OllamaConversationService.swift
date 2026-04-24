import Foundation

struct OllamaGenerationRequest: Sendable {
    let model: String
    let request: ConversationRequest
}

enum OllamaConversationError: LocalizedError {
    case invalidURL
    case badStatus(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ollama URL is invalid"
        case .badStatus(let status, let body):
            return "Ollama request failed with status \(status): \(body)"
        case .invalidResponse:
            return "Ollama response could not be decoded"
        }
    }
}

struct OllamaConversationService: Sendable {
    func generate(from input: OllamaGenerationRequest) async throws -> ConversationResponse {
        guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else {
            throw OllamaConversationError.invalidURL
        }

        let body = OllamaGenerateRequest(
            model: input.model,
            prompt: buildPrompt(from: input.request),
            format: ollamaJSONSchema,
            stream: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OllamaConversationError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw OllamaConversationError.badStatus(http.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        guard
            let responseData = decoded.response.data(using: .utf8),
            let payload = try? JSONDecoder().decode(ConversationResponsePayload.self, from: responseData)
        else {
            throw OllamaConversationError.invalidResponse
        }

        return ConversationResponse(
            primary: payload.primary,
            why: payload.why,
            next: payload.next,
            modeLabel: "Ollama \(input.model)"
        )
    }

    func generateStreaming(
        from input: OllamaGenerationRequest,
        onChunk: @Sendable @escaping (String) async -> Void
    ) async throws -> ConversationResponse {
        guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else {
            throw OllamaConversationError.invalidURL
        }

        let body = OllamaGenerateRequest(
            model: input.model,
            prompt: buildPrompt(from: input.request),
            format: ollamaJSONSchema,
            stream: true
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw OllamaConversationError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            throw OllamaConversationError.badStatus(http.statusCode, "")
        }

        var assembled = ""
        for try await line in bytes.lines {
            guard !line.isEmpty else { continue }
            let chunkData = Data(line.utf8)
            let chunk = try JSONDecoder().decode(OllamaStreamingChunk.self, from: chunkData)
            assembled += chunk.response
            await onChunk(assembled)
        }

        guard
            let responseData = assembled.data(using: .utf8),
            let payload = try? JSONDecoder().decode(ConversationResponsePayload.self, from: responseData)
        else {
            throw OllamaConversationError.invalidResponse
        }

        return ConversationResponse(
            primary: payload.primary,
            why: payload.why,
            next: payload.next,
            modeLabel: "Ollama \(input.model) (streaming)"
        )
    }

    private func buildPrompt(from request: ConversationRequest) -> String {
        let transcript = request.transcriptSegments.prefix(8).map(\.text).joined(separator: "\n")
        let sources = request.retrievalResults.prefix(3).map { result in
            "[\(result.document.fileName)] \(result.chunk.text)"
        }.joined(separator: "\n")

        return """
        You are a live meeting copilot.

        Meeting configuration:
        - meetingType: \(request.configuration.meetingType)
        - userLevel: \(request.configuration.userLevel)
        - tone: \(request.configuration.tone)
        - length: \(request.configuration.length)
        - creativity: \(request.configuration.creativity)
        - aiMode: \(request.configuration.aiMode)

        Recent transcript:
        \(transcript.isEmpty ? "None yet" : transcript)

        Retrieved context:
        \(sources.isEmpty ? "None" : sources)

        Return strict JSON with keys:
        - primary: exactly what the user should say now
        - why: why this response fits
        - next: one follow-up move
        """
    }

    private var ollamaJSONSchema: OllamaResponseSchema {
        OllamaResponseSchema(
            type: "object",
            properties: [
                "primary": .init(type: "string"),
                "why": .init(type: "string"),
                "next": .init(type: "string")
            ],
            required: ["primary", "why", "next"]
        )
    }
}

private struct OllamaGenerateRequest: Codable {
    let model: String
    let prompt: String
    let format: OllamaResponseSchema
    let stream: Bool
}

private struct OllamaGenerateResponse: Codable {
    let response: String
}

private struct OllamaStreamingChunk: Codable {
    let response: String
}

private struct OllamaResponseSchema: Codable {
    let type: String
    let properties: [String: OllamaPropertySchema]
    let required: [String]
}

private struct OllamaPropertySchema: Codable {
    let type: String
}
