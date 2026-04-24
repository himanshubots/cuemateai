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
}
