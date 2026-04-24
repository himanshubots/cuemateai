import Foundation

struct AppState: Codable, Sendable {
    var configuration: MeetingConfiguration
    var overlayContent: OverlayContent
    var clickThroughEnabled: Bool
    var isPaused: Bool
    var overlayPinnedNearCamera: Bool
    var overlayAnchor: OverlayAnchor = .topCenter
    var overlayHorizontalInset: Double = 0
    var overlayVerticalInset: Double = 0
    var confidenceMode: String
    var currentSuggestionIndex: Int
    var transcriptionProvider: TranscriptionProvider = .appleSpeech
    var generationProvider: GenerationProvider = .localHeuristic
    var autoResponseEnabled: Bool = true
}

struct ConfigStore: Sendable {
    let appPaths: AppPaths
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(appPaths: AppPaths) {
        self.appPaths = appPaths
    }

    private var stateFileURL: URL {
        appPaths.configDirectory.appendingPathComponent("app-state.json")
    }

    func load() throws -> AppState {
        let data = try Data(contentsOf: stateFileURL)
        return try decoder.decode(AppState.self, from: data)
    }

    func save(_ state: AppState) throws {
        let configuredEncoder = JSONEncoder()
        configuredEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try configuredEncoder.encode(state)
        try data.write(to: stateFileURL, options: [.atomic])
    }
}
