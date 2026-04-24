import Foundation
import SwiftUI

struct MeetingConfiguration: Equatable, Codable, Sendable {
    var speakerName = "Me"
    var meetingType = "sales"
    var userLevel = "beginner"
    var tone = "confident"
    var length = "medium"
    var creativity = "balanced"
    var aiMode = "active"
}

enum TranscriptionProvider: String, CaseIterable, Codable, Sendable, Identifiable {
    case appleSpeech
    case whisperCpp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleSpeech: "Apple Speech"
        case .whisperCpp: "whisper.cpp"
        }
    }
}

enum GenerationProvider: String, CaseIterable, Codable, Sendable, Identifiable {
    case localHeuristic
    case openAI
    case ollama

    var id: String { rawValue }

    var title: String {
        switch self {
        case .localHeuristic: "Local Heuristic"
        case .openAI: "OpenAI API"
        case .ollama: "Ollama"
        }
    }
}

struct OverlayContent: Equatable, Codable, Sendable {
    var nowSay = "Thanks for the question. Based on your current setup, the fastest path is to start with the pilot package and expand once the team sees usage."
    var why = "Keeps the answer direct, ties to business value, and avoids over-explaining before confirming budget or rollout size."
    var next = "Ask how many people would use the product in the first 30 days."
}

enum ConversationAction: String, CaseIterable, Identifiable {
    case toggleOverlay
    case pauseResume
    case nextSuggestion
    case shorten
    case expand
    case moreConfident
    case regenerate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toggleOverlay: "Show/Hide Overlay"
        case .pauseResume: "Pause/Resume"
        case .nextSuggestion: "Next Suggestion"
        case .shorten: "Shorten"
        case .expand: "Expand"
        case .moreConfident: "More Confident"
        case .regenerate: "Regenerate"
        }
    }

    var shortcutLabel: String {
        switch self {
        case .toggleOverlay: "Cmd + Shift + H"
        case .pauseResume: "Cmd + P"
        case .nextSuggestion: "Cmd + Right Arrow"
        case .shorten: "Cmd + S"
        case .expand: "Cmd + L"
        case .moreConfident: "Cmd + C"
        case .regenerate: "Cmd + R"
        }
    }
}

enum DependencyStatus: String {
    case ready
    case missing
    case optional
    case pending
    case installing
    case failed
}

struct DependencyDescriptor: Identifiable, Equatable {
    let id: String
    let title: String
    let summary: String
    let installActionTitle: String
    let validation: DependencyValidation
    let installPlan: DependencyInstallPlan?

    init(
        id: String,
        title: String,
        summary: String,
        installActionTitle: String,
        validation: DependencyValidation,
        installPlan: DependencyInstallPlan? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.installActionTitle = installActionTitle
        self.validation = validation
        self.installPlan = installPlan
    }

    static let foundation: [DependencyDescriptor] = [
        DependencyDescriptor(
            id: "ollama",
            title: "Ollama Runtime",
            summary: "Local LLM runtime for response generation and embeddings.",
            installActionTitle: "Install Runtime",
            validation: .command("ollama"),
            installPlan: DependencyInstallPlan(
                description: "Install Ollama through Homebrew, then start the app runtime.",
                commands: [
                    ["/bin/zsh", "-lc", "export PATH=\"/opt/homebrew/bin:/usr/local/bin:$PATH\"; brew install --cask ollama"],
                    ["/usr/bin/open", "-a", "Ollama"]
                ]
            )
        ),
        DependencyDescriptor(
            id: "whisper-runtime",
            title: "whisper.cpp Runtime",
            summary: "Local speech-to-text CLI used when the whisper provider is selected.",
            installActionTitle: "Install Runtime",
            validation: .command("whisper-cli"),
            installPlan: DependencyInstallPlan(
                description: "Install whisper.cpp with Homebrew so the app can invoke whisper-cli locally.",
                commands: [
                    ["/bin/zsh", "-lc", "export PATH=\"/opt/homebrew/bin:/usr/local/bin:$PATH\"; brew install whisper-cpp"]
                ]
            )
        ),
        DependencyDescriptor(
            id: "qwen3",
            title: "Qwen3 4B Model",
            summary: "Primary local response model for the MVP assistant loop.",
            installActionTitle: "Pull Model",
            validation: .ollamaModel("qwen3:4b"),
            installPlan: DependencyInstallPlan(
                description: "Pull the base local generation model into Ollama.",
                commands: [
                    ["/bin/zsh", "-lc", "ollama pull qwen3:4b"]
                ]
            )
        ),
        DependencyDescriptor(
            id: "nomic-embed",
            title: "nomic-embed-text",
            summary: "Embedding model for local semantic retrieval.",
            installActionTitle: "Pull Embed Model",
            validation: .ollamaModel("nomic-embed-text"),
            installPlan: DependencyInstallPlan(
                description: "Pull the local embedding model into Ollama.",
                commands: [
                    ["/bin/zsh", "-lc", "ollama pull nomic-embed-text"]
                ]
            )
        ),
        DependencyDescriptor(
            id: "whisper-model",
            title: "Whisper Model Bundle",
            summary: "Speech-to-text model files stored in the app support models folder for whisper.cpp.",
            installActionTitle: "Install Model",
            validation: .file(relativePath: "models/whisper/ggml-base.en.bin"),
            installPlan: DependencyInstallPlan(
                description: "Create the app model folder and download the base English GGML model into it.",
                commands: [
                    ["/bin/zsh", "-lc", "mkdir -p \"$HOME/Library/Application Support/cuemate/models/whisper\""],
                    ["/bin/zsh", "-lc", "curl -L https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin -o \"$HOME/Library/Application Support/cuemate/models/whisper/ggml-base.en.bin\""]
                ]
            )
        )
    ]
}

@MainActor
final class AppModel: ObservableObject {
    enum WorkspaceSection: String, CaseIterable, Identifiable {
        case setup
        case live
        case review
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .setup: "Setup"
            case .live: "Live"
            case .review: "Review"
            case .settings: "Settings"
            }
        }
    }

    @Published var selectedSection: WorkspaceSection? = .setup
    @Published var runtimeSetupExpanded = true
    @Published var configuration = MeetingConfiguration() {
        didSet { persistState() }
    }
    @Published var overlayContent = OverlayContent() {
        didSet {
            refreshTeleprompterState()
            persistState()
        }
    }
    @Published var dependencyItems: [InstallerItemViewModel]
    @Published var activityLog: [String] = []
    @Published var overlayVisible = false {
        didSet { persistState() }
    }
    @Published var clickThroughEnabled = false {
        didSet { persistState() }
    }
    @Published var isPaused = false {
        didSet { persistState() }
    }
    @Published var overlayPinnedNearCamera = true {
        didSet { persistState() }
    }
    @Published var confidenceMode = "confident" {
        didSet { persistState() }
    }
    @Published var currentSuggestionIndex = 0 {
        didSet { persistState() }
    }
    @Published var transcriptionProvider: TranscriptionProvider = .appleSpeech {
        didSet { persistState() }
    }
    @Published var generationProvider: GenerationProvider = .localHeuristic {
        didSet { persistState() }
    }
    @Published var autoResponseEnabled = true {
        didSet { persistState() }
    }
    @Published var importedDocuments: [IngestedDocument] = []
    @Published var lastImportedChunkCount = 0
    @Published var retrievalQuery = ""
    @Published var retrievalResults: [RetrievalSearchResult] = []
    @Published var retrievalModeLabel = "Idle"
    @Published var indexedChunkCount = 0
    @Published var isSearching = false
    @Published var audioCaptureState: AudioCaptureState = .idle
    @Published var microphonePermissionGranted = false
    @Published var audioLevel = 0.0
    @Published var capturedFrameCount = 0
    @Published var audioSampleRate = 0.0
    @Published var transcriptionState: TranscriptionState = .idle
    @Published var speechPermissionGranted = false
    @Published var transcriptSegments: [TranscriptSegment] = []
    @Published var latestTranscriptText = ""
    @Published var conversationModeLabel = "Idle"
    @Published var lastGenerationReason = ""
    @Published var voiceActivityState: VoiceActivityState = .silent
    @Published var interruptionState = "Idle"
    @Published var manualInterruptionActive = false
    @Published var teleprompterProgress = 0.0
    @Published var teleprompterReadText = ""
    @Published var teleprompterRemainingText = ""
    @Published var teleprompterStateLabel = "Idle"
    @Published var performanceSummary = PerformanceSummary()
    @Published var openAIKeyPresent = false
    @Published var providerStatusMessage = "Local providers active"
    @Published var liveResponseState = "Idle"
    @Published var streamingResponsePreview = ""
    @Published var isStreamingResponse = false
    @Published var sessionDraftTitle = ""
    @Published var meetingSessions: [MeetingSessionRecord] = []
    @Published var selectedSessionID: UUID?

    let appPaths: AppPaths

    private let installer: DependencyInstaller
    private let overlayCoordinator: OverlayPanelCoordinator
    private let configStore: ConfigStore
    private let meetingSessionStore: MeetingSessionStore
    private let documentIngestion: DocumentIngestionService
    private let retrievalEngine: RetrievalEngine
    private let audioCaptureService: AudioCaptureService
    private let speechTranscriptionService: SpeechTranscriptionService
    private let whisperCppTranscriptionService: WhisperCppTranscriptionService
    private let conversationEngine: ConversationEngine
    private let postMeetingSummaryService: PostMeetingSummaryService
    private let voiceActivityDetector: VoiceActivityDetector
    private let keychainStore: KeychainStore
    private let openAIConversationService: OpenAIConversationService
    private let ollamaConversationService: OllamaConversationService
    private var lastAudioActivityTimestamp: Date?
    private var lastAutoGeneratedTranscriptText = ""
    private var isAutoGenerating = false

    init(
        appPaths: AppPaths = .default,
        installer: DependencyInstaller? = nil,
        overlayCoordinator: OverlayPanelCoordinator = OverlayPanelCoordinator(),
        configStore: ConfigStore? = nil,
        meetingSessionStore: MeetingSessionStore? = nil,
        documentIngestion: DocumentIngestionService? = nil,
        retrievalEngine: RetrievalEngine? = nil,
        audioCaptureService: AudioCaptureService = AudioCaptureService(),
        speechTranscriptionService: SpeechTranscriptionService = SpeechTranscriptionService(),
        whisperCppTranscriptionService: WhisperCppTranscriptionService? = nil,
        conversationEngine: ConversationEngine = ConversationEngine(),
        postMeetingSummaryService: PostMeetingSummaryService = PostMeetingSummaryService(),
        voiceActivityDetector: VoiceActivityDetector = VoiceActivityDetector(),
        keychainStore: KeychainStore = KeychainStore(),
        openAIConversationService: OpenAIConversationService = OpenAIConversationService(),
        ollamaConversationService: OllamaConversationService = OllamaConversationService()
    ) {
        self.appPaths = appPaths
        self.installer = installer ?? DependencyInstaller(appPaths: appPaths)
        self.overlayCoordinator = overlayCoordinator
        self.configStore = configStore ?? ConfigStore(appPaths: appPaths)
        self.meetingSessionStore = meetingSessionStore ?? MeetingSessionStore(appPaths: appPaths)
        self.documentIngestion = documentIngestion ?? DocumentIngestionService(appPaths: appPaths)
        self.retrievalEngine = retrievalEngine ?? RetrievalEngine(appPaths: appPaths)
        self.audioCaptureService = audioCaptureService
        self.speechTranscriptionService = speechTranscriptionService
        self.whisperCppTranscriptionService = whisperCppTranscriptionService ?? WhisperCppTranscriptionService(appPaths: appPaths)
        self.conversationEngine = conversationEngine
        self.postMeetingSummaryService = postMeetingSummaryService
        self.voiceActivityDetector = voiceActivityDetector
        self.keychainStore = keychainStore
        self.openAIConversationService = openAIConversationService
        self.ollamaConversationService = ollamaConversationService
        self.dependencyItems = DependencyDescriptor.foundation.map { descriptor in
            InstallerItemViewModel(
                descriptor: descriptor,
                status: .pending,
                detail: "Not checked yet",
                progress: nil
            )
        }

        bootstrapStorage()
        loadSavedState()
        loadSecrets()
        loadDocumentLibrary()
        loadMeetingSessions()
        configureAudioCallbacks()
        configureTranscriptionCallbacks()
    }

    func bootstrapStorage() {
        do {
            try appPaths.prepareDirectories()
            appendLog("Prepared app support directories at \(appPaths.baseDirectory.path)")
        } catch {
            appendLog("Failed to prepare app support directories: \(error.localizedDescription)")
        }
    }

    func refreshDependencyStatuses() async {
        let snapshot = dependencyItems.map(\.descriptor)

        for descriptor in snapshot {
            updateStatus(for: descriptor.id, status: .pending, detail: "Checking local system state")
        }

        let statuses = await installer.inspectAll(descriptors: snapshot)

        for status in statuses {
            updateStatus(for: status.descriptor.id, status: status.status, detail: status.detail)
        }
    }

    func performInstall(for id: String) async {
        guard let item = dependencyItems.first(where: { $0.descriptor.id == id }) else {
            return
        }

        guard let plan = item.descriptor.installPlan else {
            appendLog("No automated install plan exists yet for \(item.descriptor.title).")
            updateStatus(for: id, status: .optional, detail: "Manual or bundled install path still needs implementation")
            return
        }

        updateStatus(for: id, status: .installing, detail: plan.description)
        appendLog("Running installer for \(item.descriptor.title)")

        let result = await installer.execute(plan: plan) { [weak self] step in
            await MainActor.run {
                self?.updateProgress(
                    for: id,
                    detail: "Step \(step.index) of \(step.total): \(step.commandSummary)",
                    progress: Double(step.index - 1) / Double(max(step.total, 1))
                )
            }
        }

        switch result {
        case .success:
            appendLog("Installer completed for \(item.descriptor.title)")
        case .failure(let error):
            appendLog("Installer failed for \(item.descriptor.title): \(error.localizedDescription)")
            updateStatus(for: id, status: .failed, detail: error.localizedDescription)
        }

        let refreshed = await installer.inspect(descriptor: item.descriptor)
        updateStatus(for: id, status: refreshed.status, detail: refreshed.detail)
    }

    func toggleOverlay() {
        overlayVisible.toggle()

        if overlayVisible {
            overlayCoordinator.present(model: self)
            appendLog("Overlay shown")
        } else {
            overlayCoordinator.hide()
            appendLog("Overlay hidden")
        }
    }

    func setClickThrough(_ enabled: Bool) {
        clickThroughEnabled = enabled
        overlayCoordinator.updateClickThrough(enabled)
        appendLog(enabled ? "Overlay click-through enabled" : "Overlay click-through disabled")
    }

    func cycleSuggestionLength() {
        let order = ["short", "medium", "long"]
        if let index = order.firstIndex(of: configuration.length) {
            configuration.length = order[(index + 1) % order.count]
        } else {
            configuration.length = "medium"
        }

        overlayContent = OverlayContent(
            nowSay: configuration.length == "short"
                ? "We can start with a focused pilot and scale once your team validates the workflow."
                : configuration.length == "long"
                    ? "We can begin with a focused pilot for the core team, measure adoption in the first month, and then expand to the broader rollout once we have real usage and success criteria."
                    : "We can start with a focused pilot, measure usage, and expand once the team validates the workflow.",
            why: "Changes the answer shape so the user can quickly adapt mid-call without regenerating the full context.",
            next: overlayContent.next
        )
    }

    func regenerateSuggestion() {
        overlayContent = OverlayContent(
            nowSay: "That depends on the timeline you need, but for most teams we recommend starting small, proving value quickly, and only then expanding the rollout.",
            why: "Safer, more consultative framing for situations where the other side is still evaluating options.",
            next: "Ask whether speed of rollout or depth of adoption matters more right now."
        )
        appendLog("Generated a new sample suggestion")
    }

    func shortenSuggestion() {
        configuration.length = "short"
        overlayContent = OverlayContent(
            nowSay: "Start with a pilot and expand after the team sees value.",
            why: "Keeps the answer tight for pressure moments.",
            next: overlayContent.next
        )
        appendLog("Shortened current suggestion")
    }

    func expandSuggestion() {
        configuration.length = "long"
        overlayContent = OverlayContent(
            nowSay: "We usually recommend starting with a focused pilot for the core team, measuring adoption quickly, and then expanding based on the workflows that create the clearest value in the first few weeks.",
            why: "Adds more context and rollout logic when the conversation needs a fuller answer.",
            next: overlayContent.next
        )
        appendLog("Expanded current suggestion")
    }

    func markMoreConfident() {
        confidenceMode = "assertive"
        configuration.tone = "confident"
        overlayContent = OverlayContent(
            nowSay: "The best next step is to launch a pilot now, prove the workflow with real users, and scale from evidence rather than delay the rollout.",
            why: "Raises certainty and momentum without sounding aggressive.",
            next: "Ask what would block a pilot decision this week."
        )
        appendLog("Shifted guidance to a more confident tone")
    }

    func togglePause() {
        isPaused.toggle()
        interruptionState = isPaused ? "Paused" : "Listening"
        refreshTeleprompterState()
        appendLog(isPaused ? "Teleprompter paused" : "Teleprompter resumed")
    }

    func moveToNextSuggestion() {
        currentSuggestionIndex += 1

        let suggestions = [
            OverlayContent(
                nowSay: "Before we go deeper, it would help to understand how your team handles this workflow today.",
                why: "Moves the conversation into discovery instead of defending features too early.",
                next: "Ask who owns the current process."
            ),
            OverlayContent(
                nowSay: "If speed matters most, we can get you started with the smallest workable rollout and expand from there.",
                why: "Balances urgency with low-risk adoption.",
                next: "Ask what timeline they are aiming for."
            ),
            OverlayContent(
                nowSay: "The key tradeoff is depth versus speed, and we can optimize the rollout around whichever matters more to your team.",
                why: "Useful when the other side is comparing priorities instead of features.",
                next: "Ask whether success depends more on quick launch or strong adoption."
            )
        ]

        overlayContent = suggestions[currentSuggestionIndex % suggestions.count]
        appendLog("Loaded the next suggested response")
    }

    func pinOverlayNearCamera() {
        overlayPinnedNearCamera = true
        overlayCoordinator.pinNearCamera(
            anchor: overlayAnchor,
            horizontalInset: overlayHorizontalInset,
            verticalInset: overlayVerticalInset
        )
        appendLog("Pinned overlay near the camera zone")
    }

    func appendLog(_ message: String) {
        activityLog.insert(message, at: 0)
    }

    var activeMeetingSession: MeetingSessionRecord? {
        meetingSessions.first(where: \.isActive)
    }

    var selectedReviewSession: MeetingSessionRecord? {
        guard let selectedSessionID else { return meetingSessions.first }
        return meetingSessions.first(where: { $0.id == selectedSessionID })
    }

    var recentGuidanceSnapshots: [GuidanceSnapshot] {
        guard let activeMeetingSession else { return [] }
        return Array(activeMeetingSession.guidanceHistory.prefix(4))
    }

    var currentGuidanceSourceName: String? {
        recentGuidanceSnapshots.first?.sourceDocumentName ?? retrievalResults.first?.document.fileName
    }

    func importDocument(from url: URL) {
        do {
            let result = try documentIngestion.ingest(url: url)
            importedDocuments.insert(result.document, at: 0)
            lastImportedChunkCount = result.chunks.count
            appendLog("Imported \(result.document.fileName) with \(result.chunks.count) chunks")
            indexedChunkCount += result.chunks.count
        } catch {
            appendLog("Document import failed: \(error.localizedDescription)")
        }
    }

    func runRetrieval() {
        let query = retrievalQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            retrievalResults = []
            retrievalModeLabel = "Idle"
            appendLog("Retrieval query cleared")
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            let start = Date()
            let response = try retrievalEngine.search(query: query)
            let elapsed = Date().timeIntervalSince(start) * 1000
            recordPerformance(name: "retrieval", durationMs: elapsed, budgetMs: PerformanceBudget.retrievalMs)
            retrievalResults = response.results
            retrievalModeLabel = response.modeLabel
            indexedChunkCount = response.indexedChunkCount
            appendLog("Retrieved \(response.results.count) chunk matches for query")
        } catch {
            appendLog("Retrieval failed: \(error.localizedDescription)")
        }
    }

    func generateConversationGuidance() async {
        let start = Date()
        let request = ConversationRequest(
            configuration: configuration,
            transcriptSegments: transcriptSegments,
            retrievalResults: retrievalResults
        )

        let response: ConversationResponse
        switch generationProvider {
        case .localHeuristic:
            response = conversationEngine.generate(request: request)
            providerStatusMessage = "Using local heuristic guidance"
            streamingResponsePreview = response.primary
        case .openAI:
            guard let apiKey = ((try? keychainStore.load(account: "openai_api_key")) ?? nil), !apiKey.isEmpty else {
                providerStatusMessage = "OpenAI key missing, using local heuristic guidance"
                response = conversationEngine.generate(request: request)
                streamingResponsePreview = response.primary
                break
            }
            do {
                response = try await openAIConversationService.generate(
                    from: OpenAIGenerationRequest(apiKey: apiKey, request: request)
                )
                providerStatusMessage = "Using OpenAI API"
                streamingResponsePreview = response.primary
            } catch {
                providerStatusMessage = "OpenAI failed, using local heuristic guidance"
                appendLog("OpenAI generation failed: \(error.localizedDescription)")
                response = conversationEngine.generate(request: request)
                streamingResponsePreview = response.primary
            }
        case .ollama:
            do {
                isStreamingResponse = true
                streamingResponsePreview = ""
                response = try await ollamaConversationService.generateStreaming(
                    from: OllamaGenerationRequest(model: "qwen3:4b", request: request)
                ) { [weak self] draft in
                    await MainActor.run {
                        guard let self else { return }
                        self.streamingResponsePreview = draft
                        self.liveResponseState = "Streaming response"
                    }
                }
                providerStatusMessage = "Using Ollama qwen3:4b streaming"
            } catch {
                providerStatusMessage = "Ollama failed, using local heuristic guidance"
                appendLog("Ollama generation failed: \(error.localizedDescription)")
                response = conversationEngine.generate(request: request)
                streamingResponsePreview = response.primary
            }
        }
        isStreamingResponse = false

        overlayContent = OverlayContent(
            nowSay: response.primary,
            why: response.why,
            next: response.next
        )
        recordGuidanceSnapshot(
            provider: response.modeLabel,
            retrievalQuery: retrievalQuery,
            sourceDocumentName: retrievalResults.first?.document.fileName,
            content: overlayContent
        )
        let elapsed = Date().timeIntervalSince(start) * 1000
        recordPerformance(name: "generation", durationMs: elapsed, budgetMs: PerformanceBudget.responseGenerationMs)
        conversationModeLabel = response.modeLabel
        lastGenerationReason = response.why
        appendLog("Generated response guidance from transcript and retrieval context")
    }

    func requestMicrophoneAccessAndStart() async {
        audioCaptureState = .requestingPermission
        let granted = await audioCaptureService.requestPermission()
        microphonePermissionGranted = granted

        guard granted else {
            audioCaptureState = .denied
            appendLog("Microphone permission denied")
            return
        }

        do {
            try audioCaptureService.start()
            audioCaptureState = .capturing
            interruptionState = "Listening"
            lastAudioActivityTimestamp = Date()
            if speechPermissionGranted {
                startActiveTranscriptionProvider()
                transcriptionState = .listening
            } else {
                transcriptionState = .ready
            }
            appendLog("Microphone capture started")
        } catch {
            audioCaptureState = .failed
            appendLog("Microphone capture failed: \(error.localizedDescription)")
        }
    }

    func stopMicrophoneCapture() {
        audioCaptureService.stop()
        speechTranscriptionService.stop()
        whisperCppTranscriptionService.stop()
        audioCaptureState = microphonePermissionGranted ? .ready : .idle
        transcriptionState = speechPermissionGranted ? .ready : .idle
        voiceActivityState = .silent
        interruptionState = "Idle"
        appendLog("Microphone capture stopped")
    }

    func triggerManualInterruption() {
        manualInterruptionActive = true
        isPaused = true
        interruptionState = "Manual interruption"
        refreshTeleprompterState()
        appendLog("Manual interruption triggered")
    }

    func clearManualInterruption() {
        manualInterruptionActive = false
        isPaused = false
        interruptionState = audioCaptureState == .capturing ? "Listening" : "Idle"
        refreshTeleprompterState()
        appendLog("Manual interruption cleared")
    }

    func requestSpeechAccess() async {
        switch transcriptionProvider {
        case .appleSpeech:
            transcriptionState = .requestingPermission
            let state = await speechTranscriptionService.requestPermission()

            switch state {
            case .authorized:
                speechPermissionGranted = true
                providerStatusMessage = "Using Apple Speech transcription"
                transcriptionState = audioCaptureState == .capturing ? .listening : .ready
                appendLog("Speech recognition permission granted")

                if audioCaptureState == .capturing {
                    speechTranscriptionService.start()
                }
            case .denied, .restricted:
                speechPermissionGranted = false
                transcriptionState = .denied
                appendLog("Speech recognition permission denied")
            case .notDetermined:
                transcriptionState = .idle
            }
        case .whisperCpp:
            transcriptionState = .requestingPermission
            let runtime = await whisperCppTranscriptionService.runtimeState()
            switch runtime {
            case .ready:
                speechPermissionGranted = true
                transcriptionState = audioCaptureState == .capturing ? .listening : .ready
                providerStatusMessage = "Using whisper.cpp local transcription"
                appendLog("whisper.cpp runtime is available")
                if audioCaptureState == .capturing {
                    whisperCppTranscriptionService.start()
                }
            case .missingExecutable:
                speechPermissionGranted = false
                transcriptionState = .unavailable
                providerStatusMessage = "whisper.cpp executable missing. Install later from the app setup flow."
                appendLog("whisper.cpp executable not found")
            case .missingModel:
                speechPermissionGranted = false
                transcriptionState = .unavailable
                providerStatusMessage = "whisper.cpp model missing. Add a GGML model bundle to App Support."
                appendLog("whisper.cpp model bundle not found")
            }
        }
    }

    func handleHotkeyAction(_ action: ConversationAction) {
        switch action {
        case .toggleOverlay:
            toggleOverlay()
        case .pauseResume:
            togglePause()
        case .nextSuggestion:
            moveToNextSuggestion()
        case .shorten:
            shortenSuggestion()
        case .expand:
            expandSuggestion()
        case .moreConfident:
            markMoreConfident()
        case .regenerate:
            regenerateSuggestion()
        }
    }

    func startMeetingSession() {
        let trimmedTitle = sessionDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmedTitle.isEmpty ? defaultSessionTitle(for: Date()) : trimmedTitle

        if let existingIndex = meetingSessions.firstIndex(where: \.isActive) {
            meetingSessions[existingIndex].title = title
            meetingSessions[existingIndex].configuration = configuration
            selectedSessionID = meetingSessions[existingIndex].id
            saveMeetingSessions()
            appendLog("Updated active meeting session")
            return
        }

        let session = MeetingSessionRecord(
            id: UUID(),
            title: title,
            startedAt: Date(),
            endedAt: nil,
            configuration: configuration,
            transcriptSegments: [],
            guidanceHistory: [],
            documentIDs: importedDocuments.map(\.id),
            summary: nil,
            followUpNotes: ""
        )
        meetingSessions.insert(session, at: 0)
        selectedSessionID = session.id
        selectedSection = .live
        saveMeetingSessions()
        appendLog("Started meeting session \(title)")
    }

    func endMeetingSession() {
        guard let index = meetingSessions.firstIndex(where: \.isActive) else { return }
        meetingSessions[index].endedAt = Date()
        meetingSessions[index].summary = postMeetingSummaryService.generateSummary(
            for: meetingSessions[index],
            documents: importedDocuments
        )
        selectedSessionID = meetingSessions[index].id
        selectedSection = .review
        saveMeetingSessions()
        appendLog("Ended meeting session \(meetingSessions[index].title)")
    }

    func selectSession(_ sessionID: UUID) {
        selectedSessionID = sessionID
        selectedSection = .review
    }

    func regenerateSummary(for sessionID: UUID) {
        guard let index = meetingSessions.firstIndex(where: { $0.id == sessionID }) else { return }
        meetingSessions[index].summary = postMeetingSummaryService.generateSummary(
            for: meetingSessions[index],
            documents: importedDocuments
        )
        saveMeetingSessions()
        appendLog("Regenerated post-meeting summary")
    }

    func updateFollowUpNotes(for sessionID: UUID, notes: String) {
        guard let index = meetingSessions.firstIndex(where: { $0.id == sessionID }) else { return }
        meetingSessions[index].followUpNotes = notes
        saveMeetingSessions()
    }

    private func loadDocumentLibrary() {
        do {
            let library = try documentIngestion.loadExistingLibrary()
            importedDocuments = library.documents.sorted { $0.importedAt > $1.importedAt }
            indexedChunkCount = library.chunks.count
        } catch {
            appendLog("No saved document library found yet")
        }
    }

    private func configureAudioCallbacks() {
        audioCaptureService.onFrame = { [weak self] sample in
            guard let self else { return }
            self.audioLevel = sample.level
            self.capturedFrameCount = sample.frameCount
            self.audioSampleRate = sample.sampleRate
            self.lastAudioActivityTimestamp = Date()
            let activity = self.voiceActivityDetector.process(level: sample.level)
            self.voiceActivityState = activity.state

            if self.audioCaptureState != .capturing {
                self.audioCaptureState = .ready
            }

            if !self.manualInterruptionActive {
                self.interruptionState = activity.state == .speaking ? "User speaking" : "Silence"
            }
            self.refreshTeleprompterState()
        }

        audioCaptureService.onAudioBuffer = { [weak self] buffer, _ in
            guard let self, self.speechPermissionGranted else { return }
            switch self.transcriptionProvider {
            case .appleSpeech:
                self.speechTranscriptionService.append(buffer: buffer)
            case .whisperCpp:
                self.whisperCppTranscriptionService.append(
                    buffer: buffer,
                    format: buffer.format
                )
            }
        }
    }

    private func configureTranscriptionCallbacks() {
        speechTranscriptionService.onTranscript = { [weak self] segment in
            self?.applyTranscriptSegment(segment)
        }

        whisperCppTranscriptionService.onTranscript = { [weak self] segment in
            self?.applyTranscriptSegment(segment)
        }
    }

    private func refreshTeleprompterState() {
        let start = Date()
        let targetWords = normalizedWords(from: overlayContent.nowSay)
        let spokenWords = normalizedWords(from: latestTranscriptText)

        guard !targetWords.isEmpty else {
            teleprompterProgress = 0
            teleprompterReadText = ""
            teleprompterRemainingText = ""
            teleprompterStateLabel = "Idle"
            recordPerformance(name: "ui_refresh", durationMs: Date().timeIntervalSince(start) * 1000, budgetMs: PerformanceBudget.uiRefreshMs)
            return
        }

        let matchedCount = prefixMatchCount(target: targetWords, spoken: spokenWords)
        teleprompterProgress = Double(matchedCount) / Double(max(targetWords.count, 1))
        teleprompterReadText = targetWords.prefix(matchedCount).joined(separator: " ")
        teleprompterRemainingText = targetWords.dropFirst(matchedCount).joined(separator: " ")

        if manualInterruptionActive {
            teleprompterStateLabel = "Interrupted"
        } else if isPaused {
            teleprompterStateLabel = "Paused"
        } else if voiceActivityState == .silent && audioCaptureState == .capturing {
            teleprompterStateLabel = "Waiting"
        } else if voiceActivityState == .speaking {
            teleprompterStateLabel = "Following speech"
        } else {
            teleprompterStateLabel = "Ready"
        }

        recordPerformance(name: "ui_refresh", durationMs: Date().timeIntervalSince(start) * 1000, budgetMs: PerformanceBudget.uiRefreshMs)
    }

    private func normalizedWords(from text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func prefixMatchCount(target: [String], spoken: [String]) -> Int {
        guard !spoken.isEmpty else { return 0 }

        var count = 0
        for (targetWord, spokenWord) in zip(target, spoken) {
            if targetWord == spokenWord {
                count += 1
            } else {
                break
            }
        }

        return count
    }

    private func loadSavedState() {
        do {
            let state = try configStore.load()
            configuration = state.configuration
            overlayContent = state.overlayContent
            clickThroughEnabled = state.clickThroughEnabled
            isPaused = state.isPaused
            overlayPinnedNearCamera = state.overlayPinnedNearCamera
            overlayAnchor = state.overlayAnchor
            overlayHorizontalInset = state.overlayHorizontalInset
            overlayVerticalInset = state.overlayVerticalInset
            confidenceMode = state.confidenceMode
            currentSuggestionIndex = state.currentSuggestionIndex
            transcriptionProvider = state.transcriptionProvider
            generationProvider = state.generationProvider
            autoResponseEnabled = state.autoResponseEnabled
            appendLog("Loaded saved local configuration")
        } catch {
            appendLog("Using default local configuration")
        }
    }

    private func persistState() {
        let state = AppState(
            configuration: configuration,
            overlayContent: overlayContent,
            clickThroughEnabled: clickThroughEnabled,
            isPaused: isPaused,
            overlayPinnedNearCamera: overlayPinnedNearCamera,
            overlayAnchor: overlayAnchor,
            overlayHorizontalInset: overlayHorizontalInset,
            overlayVerticalInset: overlayVerticalInset,
            confidenceMode: confidenceMode,
            currentSuggestionIndex: currentSuggestionIndex,
            transcriptionProvider: transcriptionProvider,
            generationProvider: generationProvider,
            autoResponseEnabled: autoResponseEnabled
        )

        do {
            try configStore.save(state)
        } catch {
            appendLog("Failed to save local configuration: \(error.localizedDescription)")
        }
    }

    private func updateStatus(for id: String, status: DependencyStatus, detail: String) {
        guard let index = dependencyItems.firstIndex(where: { $0.descriptor.id == id }) else {
            return
        }

        dependencyItems[index].status = status
        dependencyItems[index].detail = detail
        dependencyItems[index].progress = status == .installing ? dependencyItems[index].progress : nil
        runtimeSetupExpanded = dependencyItems.contains { item in
            switch item.status {
            case .missing, .failed, .installing, .pending:
                return true
            case .ready, .optional:
                return false
            }
        }
    }

    private func recordPerformance(name: String, durationMs: Double, budgetMs: Double) {
        performanceSummary.record(name: name, durationMs: durationMs, budgetMs: budgetMs)
    }

    private func loadMeetingSessions() {
        do {
            meetingSessions = try meetingSessionStore.loadSessions()
                .sorted { lhs, rhs in
                    let lhsDate = lhs.endedAt ?? lhs.startedAt
                    let rhsDate = rhs.endedAt ?? rhs.startedAt
                    return lhsDate > rhsDate
                }
            if selectedSessionID == nil {
                selectedSessionID = meetingSessions.first?.id
            }
        } catch {
            appendLog("Using empty meeting session history")
        }
    }

    private func saveMeetingSessions() {
        do {
            try meetingSessionStore.saveSessions(meetingSessions)
        } catch {
            appendLog("Failed to save meeting sessions: \(error.localizedDescription)")
        }
    }

    private func loadSecrets() {
        if let value = ((try? keychainStore.load(account: "openai_api_key")) ?? nil) {
            openAIKeyPresent = !value.isEmpty
        } else {
            openAIKeyPresent = false
        }
    }

    func saveOpenAIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            keychainStore.delete(account: "openai_api_key")
            openAIKeyPresent = false
            providerStatusMessage = "OpenAI key removed"
            appendLog("Removed OpenAI API key from Keychain")
            return
        }

        do {
            try keychainStore.save(value: trimmed, account: "openai_api_key")
            openAIKeyPresent = true
            providerStatusMessage = "OpenAI key saved in Keychain"
            appendLog("Saved OpenAI API key to Keychain")
        } catch {
            providerStatusMessage = "Failed to save OpenAI key"
            appendLog("Failed to save OpenAI API key: \(error.localizedDescription)")
        }
    }

    private func startActiveTranscriptionProvider() {
        switch transcriptionProvider {
        case .appleSpeech:
            speechTranscriptionService.start()
        case .whisperCpp:
            whisperCppTranscriptionService.start()
        }
    }

    private func applyTranscriptSegment(_ segment: TranscriptSegment) {
        let segment = normalizedTranscriptSegment(segment)
        if let start = lastAudioActivityTimestamp {
            let elapsed = Date().timeIntervalSince(start) * 1000
            recordPerformance(name: "transcription", durationMs: elapsed, budgetMs: PerformanceBudget.transcriptionUpdateMs)
        }
        latestTranscriptText = segment.text
        refreshTeleprompterState()

        if segment.isFinal {
            transcriptSegments.insert(segment, at: 0)
            appendTranscriptToActiveSession(segment)
            Task {
                await handleAutomaticGuidance(for: segment)
            }
        } else if let existingIndex = transcriptSegments.firstIndex(where: { !$0.isFinal && $0.speaker == segment.speaker }) {
            transcriptSegments[existingIndex] = segment
        } else {
            transcriptSegments.insert(segment, at: 0)
        }
    }

    private func handleAutomaticGuidance(for segment: TranscriptSegment) async {
        guard autoResponseEnabled else {
            liveResponseState = "Manual"
            return
        }

        let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != lastAutoGeneratedTranscriptText, !manualInterruptionActive, !isPaused else {
            return
        }

        guard !isAutoGenerating else {
            liveResponseState = "Waiting for current generation"
            return
        }

        isAutoGenerating = true
        liveResponseState = "Refreshing from live transcript"
        lastAutoGeneratedTranscriptText = trimmed
        retrievalQuery = trimmed
        runRetrieval()
        await generateConversationGuidance()
        liveResponseState = "Live guidance updated"
        isAutoGenerating = false
    }

    private func appendTranscriptToActiveSession(_ segment: TranscriptSegment) {
        guard let index = meetingSessions.firstIndex(where: \.isActive) else { return }
        meetingSessions[index].transcriptSegments.insert(segment, at: 0)
        meetingSessions[index].configuration = configuration
        saveMeetingSessions()
    }

    private func recordGuidanceSnapshot(
        provider: String,
        retrievalQuery: String,
        sourceDocumentName: String?,
        content: OverlayContent
    ) {
        guard let index = meetingSessions.firstIndex(where: \.isActive) else { return }
        let snapshot = GuidanceSnapshot(
            id: UUID(),
            createdAt: Date(),
            provider: provider,
            retrievalQuery: retrievalQuery,
            sourceDocumentName: sourceDocumentName,
            content: content
        )
        meetingSessions[index].guidanceHistory.insert(snapshot, at: 0)
        meetingSessions[index].configuration = configuration
        saveMeetingSessions()
    }

    private func defaultSessionTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Meeting \(formatter.string(from: date))"
    }

    private func normalizedTranscriptSegment(_ segment: TranscriptSegment) -> TranscriptSegment {
        guard segment.speaker.lowercased() == "user" else {
            return segment
        }

        return TranscriptSegment(
            id: segment.id,
            speaker: configuration.speakerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Me" : configuration.speakerName,
            text: segment.text,
            confidence: segment.confidence,
            isFinal: segment.isFinal,
            createdAt: segment.createdAt
        )
    }

    @Published var overlayAnchor: OverlayAnchor = .topCenter {
        didSet {
            persistState()
            syncOverlayPlacementIfNeeded()
        }
    }
    @Published var overlayHorizontalInset = 0.0 {
        didSet {
            persistState()
            syncOverlayPlacementIfNeeded()
        }
    }
    @Published var overlayVerticalInset = 0.0 {
        didSet {
            persistState()
            syncOverlayPlacementIfNeeded()
        }
    }

    private func updateProgress(for id: String, detail: String, progress: Double) {
        guard let index = dependencyItems.firstIndex(where: { $0.descriptor.id == id }) else {
            return
        }
        dependencyItems[index].detail = detail
        dependencyItems[index].progress = progress
    }

    private func syncOverlayPlacementIfNeeded() {
        guard overlayPinnedNearCamera else { return }
        overlayCoordinator.syncPlacementIfVisible(
            anchor: overlayAnchor,
            horizontalInset: overlayHorizontalInset,
            verticalInset: overlayVerticalInset
        )
    }
}

struct InstallerItemViewModel: Identifiable {
    let descriptor: DependencyDescriptor
    var status: DependencyStatus
    var detail: String
    var progress: Double?

    var id: String { descriptor.id }
}
