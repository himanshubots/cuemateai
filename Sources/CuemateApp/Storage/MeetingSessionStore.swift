import Foundation

struct MeetingSessionStore: Sendable {
    let appPaths: AppPaths

    private var sessionsURL: URL {
        appPaths.sessionsDirectory.appendingPathComponent("meeting-sessions.json")
    }

    func loadSessions() throws -> [MeetingSessionRecord] {
        guard FileManager.default.fileExists(atPath: sessionsURL.path) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: sessionsURL)
        return try decoder.decode(MeetingSessionLibrary.self, from: data).sessions
    }

    func saveSessions(_ sessions: [MeetingSessionRecord]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(MeetingSessionLibrary(sessions: sessions))
        try data.write(to: sessionsURL, options: [.atomic])
    }

    // MARK: - Targeted field updates

    /// Persists a pre-meeting brief onto an existing session record.
    /// No-ops silently if the session ID is not found.
    func saveBrief(_ brief: MeetingBrief, forSessionID id: UUID) throws {
        var sessions = try loadSessions()
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].brief = brief
        try saveSessions(sessions)
    }

    /// Persists a follow-up artifact onto an existing session record.
    /// No-ops silently if the session ID is not found.
    func saveFollowUpArtifact(_ artifact: StoredFollowUpArtifact, forSessionID id: UUID) throws {
        var sessions = try loadSessions()
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].followUpArtifact = artifact
        try saveSessions(sessions)
    }

    /// Persists a summary result (both `MeetingSummary` and `StoredFollowUpArtifact`) in one write.
    /// Avoids two separate load-modify-save cycles when both fields need updating together.
    func saveSummaryResult(_ result: SummaryResult, forSessionID id: UUID) throws {
        var sessions = try loadSessions()
        guard let index = sessions.firstIndex(where: { $0.id == id }) else { return }
        sessions[index].summary = result.summary
        sessions[index].followUpArtifact = result.followUpArtifact
        try saveSessions(sessions)
    }
}
