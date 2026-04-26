import Foundation
import SwiftUI

struct MeetingConfiguration: Equatable, Codable, Sendable {
    var speakerName = "Me"
    var meetingType = "sales"
    var userLevel = "beginner"
    var tone = "confident"
    var length = "short"
    var creativity = "balanced"
    var aiMode = "active"
}

enum MeetingMode: String, CaseIterable, Identifiable, Sendable {
    case sales
    case demo
    case clientReview = "client-review"
    case interview
    case internalSync = "internal-sync"
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sales: "Sales Call"
        case .demo: "Demo"
        case .clientReview: "Client Review"
        case .interview: "Interview"
        case .internalSync: "Internal Sync"
        case .general: "General"
        }
    }

    var summary: String {
        switch self {
        case .sales:
            "Short, outcome-focused answers with pilot and next-step framing."
        case .demo:
            "Guide the conversation toward workflow value and what to show next."
        case .clientReview:
            "Stay calm, strategic, and focused on progress, risk, and trust."
        case .interview:
            "Answer clearly, tie experience to outcomes, and keep examples tight."
        case .internalSync:
            "Push toward decisions, owners, blockers, and alignment."
        case .general:
            "Balanced guidance for mixed conversations."
        }
    }

    var defaultTone: String {
        switch self {
        case .sales, .demo, .clientReview: "confident"
        case .interview: "confident"
        case .internalSync: "technical"
        case .general: "confident"
        }
    }

    var defaultLength: String {
        switch self {
        case .sales, .demo, .clientReview: "short"
        case .interview: "medium"
        case .internalSync: "short"
        case .general: "short"
        }
    }

    var defaultUserLevel: String {
        switch self {
        case .internalSync: "expert"
        default: "beginner"
        }
    }
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
    var nowSay = "Start with a focused pilot, prove value quickly, and expand once the team sees usage."
    var why = "Keeps the answer direct and grounded in the current discussion."
    var next = "Ask what success should look like in the first two weeks."
}

enum OverlayState: String, Sendable {
    case idle
    case listening
    case questionDetected
    case recovery
    case answerReady
    case speaking
    case postAnswer
    case paused

    var title: String {
        switch self {
        case .idle: "Idle"
        case .listening: "Listening"
        case .questionDetected: "Question"
        case .recovery: "Recovery"
        case .answerReady: "Answer Ready"
        case .speaking: "Speaking"
        case .postAnswer: "Delivered"
        case .paused: "Paused"
        }
    }
}

enum GuidanceConfidence: String, Sendable {
    case low
    case medium
    case high

    var title: String { rawValue.capitalized }
}

struct ConfidenceAssessment: Sendable, Equatable {
    let level: GuidanceConfidence
    let score: Int
    let summary: String
}

enum SpeakerReadConfidence: String, Sendable {
    case low
    case medium
    case high

    var title: String { rawValue.capitalized }
}

enum LiveIntent: String, Sendable {
    case general
    case pricing
    case objection
    case decision
    case clarification
    case proof
    case nextStep

    var title: String {
        switch self {
        case .general: "General"
        case .pricing: "Pricing"
        case .objection: "Objection"
        case .decision: "Decision"
        case .clarification: "Clarification"
        case .proof: "Proof"
        case .nextStep: "Next Step"
        }
    }
}

enum SetupReadiness: String, Sendable {
    case needsSetup
    case partial
    case ready

    var title: String {
        switch self {
        case .needsSetup: "Needs Setup"
        case .partial: "Partially Ready"
        case .ready: "Ready"
        }
    }
}

enum ResponseMode: String, Sendable {
    case direct
    case safe
    case consultative
    case proof
    case close

    var title: String {
        switch self {
        case .direct: "Direct"
        case .safe: "Safe"
        case .consultative: "Consultative"
        case .proof: "Proof"
        case .close: "Close"
        }
    }
}

enum ObjectionKind: String, Sendable {
    case budget
    case timing
    case trust
    case complexity
    case adoption
    case general

    var title: String {
        switch self {
        case .budget: "Budget"
        case .timing: "Timing"
        case .trust: "Trust"
        case .complexity: "Complexity"
        case .adoption: "Adoption"
        case .general: "General"
        }
    }
}

enum DecisionKind: String, Sendable {
    case approval
    case owner
    case timeline
    case pilot
    case general

    var title: String {
        switch self {
        case .approval: "Approval"
        case .owner: "Owner"
        case .timeline: "Timeline"
        case .pilot: "Pilot"
        case .general: "General"
        }
    }
}

struct PlaybookStep: Identifiable, Sendable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
}

struct SessionDiagnostics: Sendable, Equatable {
    var recoveryEvents = 0
    var lowConfidenceEvents = 0
    var interruptionEvents = 0
    var providerFallbackEvents = 0
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
            case .setup: "Settings"
            case .live: "Start Session"
            case .review: "History"
            case .settings: "Settings"
            }
        }
    }

    @Published var selectedSection: WorkspaceSection? = .live
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
    @Published var overlayState: OverlayState = .idle
    @Published var guidanceConfidence: GuidanceConfidence = .medium
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
    @Published var historyState = HistoryState(sessions: [], documents: [])
    @Published var sessionDiagnostics = SessionDiagnostics()

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
    private var lastGuidanceFingerprint = ""
    private var isAutoGenerating = false
    private var lastGuidanceRefreshAt: Date?
    private var lastAnswerCompletionAt: Date?
    private var lastQuestionDetectedAt: Date?
    private var lastInterruptionClearedAt: Date?
    private var lastSpeakingActivityAt: Date?
    private var lastOtherSpeakerTurnAt: Date?

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
        overlayState = .answerReady
        guidanceConfidence = .medium
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

    func setPreferredResponseStyle(_ style: String) {
        confidenceMode = style

        switch style {
        case "safe":
            configuration.tone = "balanced"
            overlayContent = OverlayContent(
                nowSay: "The safest next step is to keep this small, answer directly, and verify what matters most before committing further.",
                why: "Shifts the response toward lower-risk language for uncertain or sensitive moments.",
                next: "Ask one short clarifying question before moving further."
            )
            appendLog("Shifted guidance to a safer style")
        case "assertive":
            markMoreConfident()
        case "consultative":
            configuration.tone = "balanced"
            overlayContent = OverlayContent(
                nowSay: "The best move is to answer directly, then guide the conversation with one focused follow-up question.",
                why: "Shifts the response toward collaborative framing without losing momentum.",
                next: "Ask what outcome matters most from their side right now."
            )
            appendLog("Shifted guidance to a consultative style")
        default:
            confidenceMode = "balanced"
            configuration.tone = meetingMode.defaultTone
            overlayContent = OverlayContent(
                nowSay: "Give the clearest short answer first, then add only the detail that helps the decision.",
                why: "Returns the response to a balanced default shape for most live moments.",
                next: "Ask one focused follow-up to confirm what matters most."
            )
            appendLog("Shifted guidance to a balanced style")
        }

        overlayState = .answerReady
    }

    func togglePause() {
        isPaused.toggle()
        interruptionState = isPaused ? "Paused" : "Listening"
        overlayState = isPaused ? .paused : (audioCaptureState == .capturing ? .listening : .idle)
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
        overlayState = .answerReady
        guidanceConfidence = .medium
        appendLog("Loaded the next suggested response")
    }

    func generateBuyTimeGuidance() {
        overlayContent = OverlayContent(
            nowSay: "Let me answer that in the most practical way. The short version is we should start small, confirm the goal, and then go deeper if useful.",
            why: "Buys a few seconds without sounding lost while keeping the conversation controlled.",
            next: "Ask whether they want the short answer or the detailed breakdown."
        )
        overlayState = .recovery
        guidanceConfidence = .low
        conversationModeLabel = "Buy-time fallback"
        liveResponseState = "Safe fallback ready"
        appendLog("Generated a buy-time fallback answer")
    }

    func applyMeetingMode(_ mode: MeetingMode) {
        configuration.meetingType = mode.rawValue
        configuration.tone = mode.defaultTone
        configuration.length = mode.defaultLength
        configuration.userLevel = mode.defaultUserLevel

        if overlayState == .idle || overlayState == .listening {
            overlayContent = templateOverlayContent(for: mode)
        }

        providerStatusMessage = "\(mode.title) mode active"
        appendLog("Applied \(mode.title) template")
    }

    func applyRecommendedSetupDefaults() {
        transcriptionProvider = recommendedTranscriptionProvider
        generationProvider = recommendedGenerationProvider
        autoResponseEnabled = true
        overlayPinnedNearCamera = true

        if configuration.speakerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            configuration.speakerName = "Me"
        }

        providerStatusMessage = "Applied recommended setup defaults"
        appendLog("Applied recommended setup defaults")
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

    var meetingMode: MeetingMode {
        MeetingMode(rawValue: configuration.meetingType) ?? .general
    }

    var collaboratorRoleLabel: String {
        switch meetingMode {
        case .sales:
            "Prospect"
        case .demo:
            "Prospect"
        case .clientReview:
            "Client"
        case .interview:
            "Interviewer"
        case .internalSync:
            "Teammate"
        case .general:
            "Other"
        }
    }

    var userDisplayName: String {
        let trimmed = configuration.speakerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "You" : trimmed
    }

    var latestQuestionText: String {
        if let otherLine = latestExternalSegment?.text,
           !otherLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return otherLine
        }

        let text = latestTranscriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "Waiting for the latest question or context." : text
    }

    var liveResponseText: String {
        if overlayState == .postAnswer {
            return "Answer delivered. Waiting for the next question."
        }

        let remaining = teleprompterRemainingText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !remaining.isEmpty, teleprompterProgress > 0.08 {
            return remaining
        }
        return overlayContent.nowSay
    }

    var latestContextText: String {
        if overlayState == .recovery {
            return overlayContent.why
        }

        let reason = overlayContent.why.trimmingCharacters(in: .whitespacesAndNewlines)
        if !reason.isEmpty {
            return reason
        }
        if let source = retrievalResults.first?.document.fileName {
            return "Using context from \(source)."
        }
        return "Using recent live transcript."
    }

    var liveContextSummary: String {
        let segments = liveContextSegments()
        guard !segments.isEmpty else {
            return "Waiting for enough stable context."
        }

        let context = segments.prefix(3).map { segment in
            let speaker = normalizedSpeakerName(segment.speaker) == normalizedSpeakerName(userDisplayName) ? "You" : collaboratorRoleLabel
            let text = firstSentence(in: segment.text).trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(speaker): \(text)"
        }

        return context.joined(separator: "  ")
    }

    var speakerReadSummary: String {
        let role = collaboratorRoleLabel
        let level = speakerReadConfidence.title
        return "\(role) read \(level.lowercased())"
    }

    var speakerReadConfidence: SpeakerReadConfidence {
        guard let latestExternalSegment else { return .low }

        let trimmed = latestExternalSegment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .low
        }

        if isLikelyOtherSpeaker(text: trimmed.lowercased()) && latestExternalSegment.confidence >= 0.72 {
            return .high
        }

        if latestExternalSegment.confidence >= 0.55 || isLikelyOtherSpeaker(text: trimmed.lowercased()) {
            return .medium
        }

        return .low
    }

    var overlayStatusSummary: String {
        switch overlayState {
        case .recovery:
            return "Missed context recovery"
        case .answerReady:
            return guidanceConfidence == .low ? "Safe answer ready" : "Answer ready"
        default:
            return overlayState.title
        }
    }

    var overlayActionText: String {
        if overlayState == .recovery && guidanceConfidence == .low {
            return "Use the short answer, then ask one clarifying question."
        }
        return overlayContent.next
    }

    var recoverySummaryText: String? {
        guard overlayState == .recovery else { return nil }
        return recoveryDetailParts().summary
    }

    var recoveryNeedText: String? {
        guard overlayState == .recovery else { return nil }
        return recoveryDetailParts().need
    }

    var detectedIntent: LiveIntent {
        detectIntent(from: latestQuestionText)
    }

    var suggestedResponseMode: ResponseMode {
        let assessment = currentConfidenceAssessment
        let preferredStyle = confidenceMode

        if manualInterruptionActive || assessment.level == .low {
            switch detectedIntent {
            case .clarification:
                return .consultative
            default:
                return preferredStyle == "assertive" ? .direct : .safe
            }
        }

        if assessment.level == .medium {
            switch detectedIntent {
            case .decision, .nextStep:
                return preferredStyle == "consultative" ? .consultative : .direct
            case .proof:
                return .proof
            case .clarification:
                return .consultative
            case .pricing, .objection:
                return preferredStyle == "assertive" ? .direct : .safe
            case .general:
                return preferredStyle == "safe" ? .safe : .direct
            }
        }

        switch detectedIntent {
        case .pricing, .objection:
            return preferredStyle == "assertive" ? .direct : .safe
        case .decision, .nextStep:
            return preferredStyle == "consultative" ? .consultative : .close
        case .proof:
            return .proof
        case .clarification:
            return .consultative
        case .general:
            return preferredStyle == "safe" ? .safe : .direct
        }
    }

    var confidenceScoreLabel: String {
        "\(currentConfidenceAssessment.score)%"
    }

    var confidenceSignalSummary: String {
        currentConfidenceAssessment.summary
    }

    var preferredResponseStyleTitle: String {
        switch confidenceMode {
        case "safe":
            return "Safe"
        case "assertive":
            return "Assertive"
        case "consultative":
            return "Consultative"
        default:
            return "Balanced"
        }
    }

    var preferredResponseStyleSummary: String {
        switch confidenceMode {
        case "safe":
            return "Bias toward lower-risk answers and quick verification."
        case "assertive":
            return "Bias toward direct answers and stronger next-step framing."
        case "consultative":
            return "Bias toward collaborative language and guided follow-up."
        default:
            return "Balance directness, caution, and forward motion."
        }
    }

    var liveMomentLabel: String {
        switch detectedIntent {
        case .objection:
            return "Objection: \(currentObjectionKind.title)"
        case .decision:
            return "Decision: \(currentDecisionKind.title)"
        case .pricing:
            return "Pricing"
        case .nextStep:
            return "Next Step"
        case .proof:
            return "Proof"
        case .clarification:
            return "Clarification"
        case .general:
            return "General"
        }
    }

    var meetingModeFocusSummary: String {
        switch meetingMode {
        case .sales:
            return "Keep the conversation moving toward business value, a small commitment, and a concrete next step."
        case .demo:
            return "Anchor everything in workflow value and the next best thing to show."
        case .clientReview:
            return "Lead with progress, risk clarity, and calm accountability."
        case .interview:
            return "Answer directly, tie it to outcomes, and keep one example ready."
        case .internalSync:
            return "Push toward owner, blocker, decision, and next action."
        case .general:
            return "Keep the answer clear, useful, and easy to act on."
        }
    }

    var meetingModeRiskSummary: String {
        switch meetingMode {
        case .sales:
            return "Do not drift into feature detail before value, scope, and next step are clear."
        case .demo:
            return "Do not feature-dump when one workflow proof would move the conversation faster."
        case .clientReview:
            return "Do not sound defensive when the moment really needs clarity and ownership."
        case .interview:
            return "Do not over-answer when a tighter outcome-first story would land better."
        case .internalSync:
            return "Do not leave without a clear owner or let alignment stay abstract."
        case .general:
            return "Do not add more detail than the decision actually needs."
        }
    }

    var liveRiskFlags: [String] {
        var flags: [String] = []

        if guidanceConfidence == .low {
            flags.append("Low confidence: verify the ask before leaning on the full answer.")
        }

        if speakerReadConfidence == .low {
            flags.append("Speaker uncertainty: the latest line may not be classified cleanly yet.")
        }

        if manualInterruptionActive {
            flags.append("Interruption active: re-enter with one short line before expanding.")
        }

        if overlayState == .recovery {
            flags.append("Recovery mode: stay short and confirm what they actually need.")
        }

        if generationProvider == .openAI {
            flags.append("External provider active: sensitive context may leave the machine.")
        }

        if voiceActivityState == .speaking && teleprompterProgress > 0.72 {
            flags.append("Answer almost landed: stop cleanly instead of adding extra detail.")
        }

        if liveContextSegments().count <= 1 && guidanceConfidence != .high {
            flags.append("Thin context: the answer is based on a narrow conversation window.")
        }

        return Array(flags.prefix(3))
    }

    var coachingCue: String {
        if overlayState == .recovery {
            return "Answer short first, then ask one clarifying question."
        }

        if manualInterruptionActive {
            return "You were interrupted. Re-enter with one short sentence and then take control with a focused follow-up."
        }

        if overlayState == .speaking && teleprompterProgress > 0.65 {
            return "Land the point now and stop cleanly."
        }

        switch detectedIntent {
        case .pricing:
            return "Do not defend price first. Frame value, scope, and rollout size."
        case .objection:
            switch currentObjectionKind {
            case .budget:
                return "Do not fight the number. Shrink scope first, then reconnect spend to value."
            case .timing:
                return "Reduce the time risk. Offer the smallest next step that fits their window."
            case .trust:
                return "Lower the trust risk. Use proof, references, or a safer rollout path."
            case .complexity:
                return "Simplify the motion. Make the path sound easier than the fear behind it."
            case .adoption:
                return "Answer the human risk. Show how the team can adopt this without heavy change."
            case .general:
                return "Lower the risk. Acknowledge concern, then give the simplest safe path."
            }
        case .decision:
            switch currentDecisionKind {
            case .approval:
                return "Make approval easy. Reduce the ask, then name the exact decision on the table."
            case .owner:
                return "Push for ownership. End with one owner, one move, and one date."
            case .timeline:
                return "Turn the decision into timing. Anchor on the next date, not abstract alignment."
            case .pilot:
                return "Use the pilot as the decision bridge. Keep the commitment small and outcome-focused."
            case .general:
                return "Push toward commitment. Name the next step and who owns it."
            }
        case .clarification:
            return "Answer directly first, then add one supporting detail."
        case .proof:
            return "Use one concrete example or proof point, not three."
        case .nextStep:
            return "Make the next step specific: owner, timeline, and outcome."
        case .general:
            switch meetingMode {
            case .sales:
                return "Keep it short, tie it to value, and move toward the next commitment."
            case .demo:
                return "Keep it short, tie it to workflow value, and guide what to show next."
            case .clientReview:
                return "Keep it calm, clear, and anchored in progress plus the next action."
            case .interview:
                return "Answer directly first, then connect it to an outcome with one example ready."
            case .internalSync:
                return "Keep it practical and decision-oriented: owner, blocker, next step."
            case .general:
                return "Keep it short, clear, and easy to act on."
            }
        }
    }

    var confidenceAdvice: String {
        if manualInterruptionActive {
            return "Re-enter safely: one short sentence, then confirm the next point."
        }

        switch currentConfidenceAssessment.level {
        case .low:
            return "Signal quality is weak. Stay safe, answer in one line, and verify the exact need."
        case .medium:
            return "Signal quality is usable. Answer directly, then keep one clarifying follow-up ready."
        case .high:
            return "Signal quality is strong. Answer directly and move toward the next step."
        }
    }

    var interruptionRecoveryStep: String? {
        guard manualInterruptionActive else { return nil }

        switch detectedIntent {
        case .objection:
            return "Re-enter by acknowledging the concern, then give the smallest safe path."
        case .decision:
            return "Re-enter by naming the next decision in one sentence, then assign the owner."
        case .pricing:
            return "Re-enter by framing scope and value before budget detail."
        case .nextStep:
            return "Re-enter by naming one next step, one owner, and one timeline."
        case .proof:
            return "Re-enter with one proof point only, then stop."
        case .clarification, .general:
            return "Re-enter with the direct answer first, then ask a focused follow-up."
        }
    }

    var liveDecisionCue: String {
        if manualInterruptionActive {
            return "Re-enter"
        }

        if overlayState == .speaking && teleprompterProgress > 0.7 {
            return "Stop"
        }

        if currentConfidenceAssessment.level == .low {
            return "Verify"
        }

        switch detectedIntent {
        case .decision, .nextStep:
            return "Close"
        case .clarification, .proof:
            return "Clarify"
        case .objection, .pricing:
            return "Reduce Risk"
        case .general:
            return "Answer"
        }
    }

    private var currentConfidenceAssessment: ConfidenceAssessment {
        confidenceAssessment(
            request: ConversationRequest(
                configuration: configuration,
                transcriptSegments: transcriptSegments,
                retrievalResults: retrievalResults
            )
        )
    }

    private var currentObjectionKind: ObjectionKind {
        detectObjectionKind(from: latestQuestionText)
    }

    private var currentDecisionKind: DecisionKind {
        detectDecisionKind(from: latestQuestionText)
    }

    private var latestExternalSegment: TranscriptSegment? {
        liveContextSegments().first(where: { normalizedSpeakerName($0.speaker) != normalizedSpeakerName(userDisplayName) })
    }

    var activePlaybookTitle: String {
        switch detectedIntent {
        case .objection:
            return "\(currentObjectionKind.title) Objection Playbook"
        case .decision:
            return "\(currentDecisionKind.title) Decision Playbook"
        case .pricing:
            return "Pricing Playbook"
        case .nextStep:
            return "Next-Step Playbook"
        default:
            return "Response Playbook"
        }
    }

    var activePlaybookSteps: [PlaybookStep] {
        switch detectedIntent {
        case .objection:
            switch currentObjectionKind {
            case .budget:
                return [
                    PlaybookStep(title: "Shrink Scope", detail: "Make the first step smaller before discussing the full investment."),
                    PlaybookStep(title: "Reconnect Value", detail: "Tie cost to the outcome, team size, or rollout stage they care about."),
                    PlaybookStep(title: "Qualify Range", detail: "Ask what budget range or starting team size feels realistic.")
                ]
            case .timing:
                return [
                    PlaybookStep(title: "Acknowledge Timing", detail: "Show that you understand the pressure or competing priorities."),
                    PlaybookStep(title: "Reduce The Ask", detail: "Offer the smallest next move that can happen inside their current window."),
                    PlaybookStep(title: "Protect Momentum", detail: "Lock one date or checkpoint so the conversation does not drift.")
                ]
            case .trust:
                return [
                    PlaybookStep(title: "Lower Perceived Risk", detail: "Acknowledge the trust gap without sounding defensive."),
                    PlaybookStep(title: "Use Proof", detail: "Give one concrete reference, example, or validation point."),
                    PlaybookStep(title: "Offer A Safe Path", detail: "Propose a reversible step that lets them validate before committing.")
                ]
            case .complexity:
                return [
                    PlaybookStep(title: "Simplify The Story", detail: "Translate the answer into the smallest understandable path."),
                    PlaybookStep(title: "Reduce Change", detail: "Show what does not need to change yet."),
                    PlaybookStep(title: "Anchor On First Win", detail: "Focus on one practical outcome instead of the full system.")
                ]
            case .adoption:
                return [
                    PlaybookStep(title: "Acknowledge Team Friction", detail: "Recognize that adoption risk is usually about change load, not only features."),
                    PlaybookStep(title: "Start Small", detail: "Offer a first group or use case that can adopt without disrupting everyone."),
                    PlaybookStep(title: "Show Support Path", detail: "Make training, onboarding, or rollout support feel easy and specific.")
                ]
            case .general:
                return [
                    PlaybookStep(title: "Acknowledge", detail: "Show that you understand the concern before pushing a solution."),
                    PlaybookStep(title: "Reduce Risk", detail: "Offer the smallest safe path instead of the full commitment."),
                    PlaybookStep(title: "Reconfirm Goal", detail: "Tie the answer back to the result they actually care about.")
                ]
            }
        case .decision:
            switch currentDecisionKind {
            case .approval:
                return [
                    PlaybookStep(title: "Name The Decision", detail: "Say exactly what approval is needed right now."),
                    PlaybookStep(title: "Keep It Reversible", detail: "Frame the move as a small commitment, not a full locked-in outcome."),
                    PlaybookStep(title: "Confirm The Path", detail: "Ask what needs to happen for approval to move today.")
                ]
            case .owner:
                return [
                    PlaybookStep(title: "Choose One Owner", detail: "Do not let the next step belong to everyone."),
                    PlaybookStep(title: "Name The Move", detail: "Pair the owner with one explicit action."),
                    PlaybookStep(title: "Set The Date", detail: "Anchor the action to a real date or checkpoint.")
                ]
            case .timeline:
                return [
                    PlaybookStep(title: "Anchor The Date", detail: "Turn alignment into a specific time commitment."),
                    PlaybookStep(title: "Back Into The Step", detail: "Pick the smallest step that protects that timing."),
                    PlaybookStep(title: "Remove Blockers", detail: "Ask what could delay the date and how to remove it now.")
                ]
            case .pilot:
                return [
                    PlaybookStep(title: "Use Pilot Framing", detail: "Make the next commitment feel like validation, not a full rollout."),
                    PlaybookStep(title: "Define Success", detail: "Name what the pilot should prove and for whom."),
                    PlaybookStep(title: "Lock Owner And Timing", detail: "Leave with a responsible owner and a start point.")
                ]
            case .general:
                return [
                    PlaybookStep(title: "State The Move", detail: "Name the clearest next decision in one sentence."),
                    PlaybookStep(title: "Make It Small", detail: "Keep the next commitment easy to say yes to."),
                    PlaybookStep(title: "Assign Ownership", detail: "Close with who owns the next step and when it happens.")
                ]
            }
        case .pricing:
            return [
                PlaybookStep(title: "Frame Scope", detail: "Talk about the right initial scope before defending price."),
                PlaybookStep(title: "Connect Value", detail: "Tie spend to adoption, outcome, or rollout size."),
                PlaybookStep(title: "Qualify Budget", detail: "Ask what range or first-team size they have in mind.")
            ]
        case .nextStep:
            return [
                PlaybookStep(title: "Choose One Step", detail: "Do not leave with multiple parallel actions."),
                PlaybookStep(title: "Set Timeline", detail: "Make the next step date-bound if possible."),
                PlaybookStep(title: "Confirm Outcome", detail: "Name what success looks like after the next step.")
            ]
        case .clarification, .proof, .general:
            return [
                PlaybookStep(title: "Answer First", detail: "Lead with the short direct answer."),
                PlaybookStep(title: "Support Lightly", detail: "Add only one supporting point unless they ask for more."),
                PlaybookStep(title: "Keep Momentum", detail: "End with one useful follow-up move.")
            ]
        }
    }

    var playbookRiskToAvoid: String {
        switch detectedIntent {
        case .objection:
            switch currentObjectionKind {
            case .budget:
                return "Do not defend price before resizing the scope."
            case .timing:
                return "Do not answer time pressure with a bigger ask."
            case .trust:
                return "Do not push harder before trust is restored."
            case .complexity:
                return "Do not make the path sound heavier than it needs to be."
            case .adoption:
                return "Do not ignore rollout friction and change management."
            case .general:
                return "Do not argue or over-explain before reducing the perceived risk."
            }
        case .decision:
            switch currentDecisionKind {
            case .approval:
                return "Do not ask for broad approval when a smaller commitment would move faster."
            case .owner:
                return "Do not leave ownership implied or shared by everyone."
            case .timeline:
                return "Do not leave the timeline as a feeling instead of a date."
            case .pilot:
                return "Do not pitch the pilot like a full rollout."
            case .general:
                return "Do not end with a vague next step or no owner."
            }
        case .pricing:
            return "Do not defend price in isolation from scope and value."
        case .nextStep:
            return "Do not leave the next step open-ended."
        case .clarification:
            return "Do not bury the answer inside too much background."
        case .proof:
            return "Do not give too many examples. Use one strong proof point."
        case .general:
            return "Do not turn a short answer into a long monologue."
        }
    }

    var recommendedTranscriptionProvider: TranscriptionProvider {
        dependencyStatus(for: "whisper-runtime") == .ready && dependencyStatus(for: "whisper-model") == .ready
            ? .whisperCpp
            : .appleSpeech
    }

    var recommendedGenerationProvider: GenerationProvider {
        dependencyStatus(for: "ollama") == .ready && dependencyStatus(for: "qwen3") == .ready
            ? .ollama
            : .localHeuristic
    }

    var setupReadiness: SetupReadiness {
        let localReady = dependencyStatus(for: "ollama") == .ready && dependencyStatus(for: "qwen3") == .ready
        let speechReady = speechPermissionGranted || transcriptionProvider == .appleSpeech
        let microphoneReady = microphonePermissionGranted || audioCaptureState == .idle || audioCaptureState == .ready

        if localReady && speechReady && microphoneReady {
            return .ready
        }

        let anyReady = dependencyItems.contains(where: { $0.status == .ready }) || speechPermissionGranted || microphonePermissionGranted
        return anyReady ? .partial : .needsSetup
    }

    var setupChecklistItems: [(title: String, detail: String, done: Bool)] {
        [
            (
                title: "Microphone access",
                detail: microphonePermissionGranted ? "Microphone permission granted." : "Grant microphone access before a live meeting.",
                done: microphonePermissionGranted
            ),
            (
                title: "Speech pipeline",
                detail: transcriptionProvider == .whisperCpp
                    ? (dependencyStatus(for: "whisper-runtime") == .ready && dependencyStatus(for: "whisper-model") == .ready
                        ? "whisper.cpp is ready for local transcription."
                        : "whisper.cpp still needs runtime or model setup.")
                    : "Apple Speech is selected for fast setup.",
                done: transcriptionProvider == .appleSpeech || (dependencyStatus(for: "whisper-runtime") == .ready && dependencyStatus(for: "whisper-model") == .ready)
            ),
            (
                title: "Response engine",
                detail: recommendedGenerationProvider == .ollama
                    ? "Ollama local generation is available."
                    : "Local heuristic guidance is available even without Ollama.",
                done: recommendedGenerationProvider == .ollama || generationProvider == .localHeuristic
            ),
            (
                title: "Overlay placement",
                detail: overlayVisible ? "Overlay is visible and ready to test." : "Show the overlay once before a real call to confirm placement.",
                done: overlayVisible
            )
        ]
    }

    var preMeetingBriefItems: [String] {
        var items: [String] = []

        switch meetingMode {
        case .sales:
            items.append("Open with the business outcome, not the feature detail.")
            items.append("Be ready for pricing, rollout size, and pilot questions.")
            items.append("Leave the meeting with one concrete next step.")
        case .demo:
            items.append("Anchor every answer in workflow value.")
            items.append("Keep one clean path for what to show next.")
            items.append("Avoid feature dumping unless they ask for depth.")
        case .clientReview:
            items.append("Lead with progress, current risk, and next action.")
            items.append("Be ready to explain timeline, trust, and ownership clearly.")
            items.append("Keep the tone calm and accountable.")
        case .interview:
            items.append("Answer directly, then support it with one strong example.")
            items.append("Tie experience to outcomes they care about.")
            items.append("Keep a short version and deeper version ready.")
        case .internalSync:
            items.append("Push for decision, owner, blocker, and next step.")
            items.append("Avoid over-explaining background unless needed.")
            items.append("Keep alignment visible in every answer.")
        case .general:
            items.append("Give the clearest short answer first.")
            items.append("Use follow-up questions to narrow what matters most.")
            items.append("Keep one safe fallback ready if context is thin.")
        }

        if importedDocuments.isEmpty {
            items.append("No local documents attached yet, so responses may rely more on live transcript.")
        } else {
            items.append("\(importedDocuments.count) local document(s) are available for context.")
        }

        if let lastSession = meetingSessions.first(where: { !$0.isActive }) {
            items.append("Last saved session: \(lastSession.title). Review follow-up commitments before you start.")
        }

        return items
    }

    var recurringMemoryItems: [String] {
        let priorSessions = meetingSessions
            .filter { !$0.isActive && $0.configuration.meetingType == configuration.meetingType }
            .prefix(4)

        guard !priorSessions.isEmpty else {
            return ["No recurring memory yet. Complete a few sessions to build continuity here."]
        }

        var items: [String] = []

        if let lastSummary = priorSessions.compactMap(\.summary).first {
            if !lastSummary.outcomeNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                items.append("Last outcome: \(lastSummary.outcomeNote)")
            }
            if let firstAction = lastSummary.actionItems.first, !firstAction.isEmpty {
                items.append("Recent follow-through: \(firstAction)")
            }
        }

        let topicCounts = Dictionary(grouping: priorSessions.flatMap { $0.summary?.keyTopics ?? [] }.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }, by: { $0 })
            .mapValues(\.count)
            .sorted { lhs, rhs in
                if lhs.value == rhs.value {
                    return lhs.key < rhs.key
                }
                return lhs.value > rhs.value
            }
            .prefix(3)
            .map(\.key)

        if !topicCounts.isEmpty {
            items.append("Recurring themes: " + topicCounts.joined(separator: ", "))
        }

        let recurringRisks = priorSessions.compactMap { $0.summary?.decisionSummary }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(1)

        if let risk = recurringRisks.first {
            items.append("Decision pattern: \(risk)")
        }

        return Array(items.prefix(3))
    }

    var privacyExecutionSummary: String {
        switch generationProvider {
        case .localHeuristic:
            return "Responses stay on this machine with the local heuristic engine."
        case .ollama:
            return "Responses use the local Ollama runtime on this machine."
        case .openAI:
            return "Response generation can send meeting context to the OpenAI API when enabled."
        }
    }

    var privacyTranscriptionSummary: String {
        switch transcriptionProvider {
        case .appleSpeech:
            return "Transcription uses Apple Speech on-device when available through the selected system path."
        case .whisperCpp:
            return "Transcription uses the local whisper.cpp runtime and model files on this machine."
        }
    }

    var privacyStorageItems: [String] {
        [
            "\(importedDocuments.count) document(s) stored locally for retrieval context.",
            "\(meetingSessions.count) meeting session(s) stored locally with transcript, guidance, and recap data.",
            openAIKeyPresent ? "OpenAI API key is stored locally in Keychain." : "No OpenAI API key is currently stored."
        ]
    }

    var privacyBoundaryItems: [String] {
        var items = [
            "Overlay content, meeting sessions, briefs, and follow-up artifacts are stored in local app support data.",
            "Provider status shows which response path is active before and during a session."
        ]

        if generationProvider == .openAI {
            items.append("When OpenAI is selected, the meeting request payload may leave this machine for response generation.")
        } else {
            items.append("With local response providers selected, meeting response generation stays on this machine.")
        }

        return items
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
        let request = liveConversationRequest()
        let confidence = guidanceConfidenceLevel(for: request)

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

        let latestQuestion = request.transcriptSegments.first(where: {
            normalizedSpeakerName($0.speaker) != normalizedSpeakerName(userDisplayName)
        })?.text ?? latestTranscriptText
        let intent = detectIntent(from: latestQuestion)

        overlayContent = OverlayContent(
            nowSay: shapedPrimaryResponse(from: response.primary, confidence: confidence, intent: intent),
            why: shapedReason(from: response.why, confidence: confidence, intent: intent),
            next: shapedNextStep(from: response.next, intent: intent)
        )
        guidanceConfidence = confidence
        overlayState = .answerReady
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
            overlayState = .listening
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
        overlayState = .idle
        appendLog("Microphone capture stopped")
    }

    func triggerManualInterruption() {
        manualInterruptionActive = true
        isPaused = true
        interruptionState = "Manual interruption"
        overlayState = .paused
        refreshTeleprompterState()
        appendLog("Manual interruption triggered")
    }

    func clearManualInterruption() {
        manualInterruptionActive = false
        isPaused = false
        lastInterruptionClearedAt = Date()
        interruptionState = audioCaptureState == .capturing ? "Re-entering" : "Idle"
        overlayState = audioCaptureState == .capturing ? .answerReady : .idle
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
            let sessionID = meetingSessions[existingIndex].id
            selectedSessionID = sessionID
            saveMeetingSessions()
            Task {
                await generateBriefForSession(sessionID: sessionID)
            }
            appendLog("Updated active meeting session")
            return
        }

        let session = MeetingSessionRecord.makeNew(
            configuration: configuration,
            title: title,
            documentIDs: importedDocuments.map(\.id)
        )

        do {
            try meetingSessionStore.createSession(session)
            loadMeetingSessions()
        } catch {
            meetingSessions.insert(session, at: 0)
            selectedSessionID = session.id
            saveMeetingSessions()
            appendLog("Fell back to local session creation: \(error.localizedDescription)")
        }

        selectedSessionID = session.id
        selectedSection = .live
        appendLog("Started meeting session \(title)")

        Task {
            await generateBriefForSession(sessionID: session.id)
        }
    }

    func endMeetingSession() {
        guard let index = meetingSessions.firstIndex(where: \.isActive) else { return }
        let sessionID = meetingSessions[index].id
        let endedAt = Date()
        let result = postMeetingSummaryService.generateResult(
            for: meetingSessions[index],
            documents: importedDocuments
        )

        meetingSessions[index].endedAt = endedAt
        meetingSessions[index].summary = result.summary
        meetingSessions[index].followUpArtifact = result.followUpArtifact

        do {
            try meetingSessionStore.saveSummaryResult(result, forSessionID: sessionID)
            try meetingSessionStore.endSession(id: sessionID, at: endedAt)
            loadMeetingSessions()
        } catch {
            saveMeetingSessions()
            appendLog("Fell back to full session save on end: \(error.localizedDescription)")
        }

        selectedSessionID = sessionID
        selectedSection = .review
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
        refreshHistoryState()
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
            if activity.state == .speaking {
                self.lastSpeakingActivityAt = Date()
            }

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
            syncOverlayStateFromLiveSignals()
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

        syncOverlayStateFromLiveSignals()

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
        refreshHistoryState()
    }

    private func saveMeetingSessions() {
        do {
            try meetingSessionStore.saveSessions(meetingSessions)
        } catch {
            appendLog("Failed to save meeting sessions: \(error.localizedDescription)")
        }
        refreshHistoryState()
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
            if normalizedSpeakerName(segment.speaker) != normalizedSpeakerName(userDisplayName) {
                lastOtherSpeakerTurnAt = Date()
            }
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

        if let waitReason = guidanceStabilityReason(for: segment) {
            liveResponseState = waitReason
            return
        }

        if shouldUseRecoveryMode(for: segment) {
            applyRecoveryMode(for: segment)
            lastAutoGeneratedTranscriptText = trimmed
            return
        }

        guard !isAutoGenerating else {
            liveResponseState = "Waiting for current generation"
            return
        }

        if let lastGuidanceRefreshAt,
           Date().timeIntervalSince(lastGuidanceRefreshAt) < 1.6 {
            liveResponseState = "Waiting for stable transcript"
            return
        }

        let fingerprint = guidanceFingerprint(for: segment)
        if fingerprint == lastGuidanceFingerprint {
            liveResponseState = "Holding steady on current guidance"
            return
        }

        isAutoGenerating = true
        overlayState = .questionDetected
        lastQuestionDetectedAt = Date()
        liveResponseState = "Refreshing from live transcript"
        lastAutoGeneratedTranscriptText = trimmed
        retrievalQuery = trimmed
        runRetrieval()
        await generateConversationGuidance()
        liveResponseState = "Live guidance updated"
        lastGuidanceRefreshAt = Date()
        lastGuidanceFingerprint = fingerprint
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

    private func generateBriefForSession(sessionID: UUID) async {
        let snapshot = loadDocumentSnapshot()
        let input = BriefCoordinator.Input(
            configuration: configuration,
            snapshot: snapshot,
            documentIDs: importedDocuments.map(\.id),
            priorSessions: meetingSessions.filter { !$0.isActive },
            strategy: selectedBriefGenerationStrategy()
        )

        let brief = await BriefCoordinator().build(from: input)

        do {
            try meetingSessionStore.saveBrief(brief, forSessionID: sessionID)
        } catch {
            appendLog("Failed to persist meeting brief: \(error.localizedDescription)")
        }

        if let index = meetingSessions.firstIndex(where: { $0.id == sessionID }) {
            meetingSessions[index].brief = brief
        }
        refreshHistoryState()
        appendLog("Prepared session brief")
    }

    private func loadDocumentSnapshot() -> DocumentLibrarySnapshot {
        (try? documentIngestion.loadExistingLibrary()) ?? DocumentLibrarySnapshot(documents: importedDocuments, chunks: [])
    }

    private func selectedBriefGenerationStrategy() -> BriefGenerationStrategy {
        switch generationProvider {
        case .ollama:
            return .ollama(model: "qwen3:4b")
        case .openAI:
            if let apiKey = ((try? keychainStore.load(account: "openai_api_key")) ?? nil), !apiKey.isEmpty {
                return .openAI(apiKey: apiKey, model: "gpt-5.4-mini")
            }
            return .heuristicOnly
        case .localHeuristic:
            return .heuristicOnly
        }
    }

    private func refreshHistoryState() {
        let snapshot = loadDocumentSnapshot()
        let coordinator = SessionHistoryCoordinator(store: meetingSessionStore, documentLibrary: snapshot)

        do {
            historyState = try coordinator.loadState()
        } catch {
            historyState = HistoryState(sessions: meetingSessions, documents: snapshot.documents)
        }
    }

    private func defaultSessionTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Meeting \(formatter.string(from: date))"
    }

    private func normalizedTranscriptSegment(_ segment: TranscriptSegment) -> TranscriptSegment {
        let inferredSpeaker = inferredSpeakerName(for: segment)

        return TranscriptSegment(
            id: segment.id,
            speaker: inferredSpeaker,
            text: segment.text,
            confidence: segment.confidence,
            isFinal: segment.isFinal,
            createdAt: segment.createdAt
        )
    }

    private func inferredSpeakerName(for segment: TranscriptSegment) -> String {
        let originalSpeaker = normalizedSpeakerName(segment.speaker)
        let userSpeaker = normalizedSpeakerName(userDisplayName)
        let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedText = text.lowercased()

        guard originalSpeaker == "user" else {
            return segment.speaker
        }

        if isLikelyOtherSpeaker(text: normalizedText) {
            return collaboratorRoleLabel
        }

        if isLikelyUserResponse(text: normalizedText) {
            return userSpeaker.isEmpty ? "You" : userDisplayName
        }

        let answerWords = Set(normalizedWords(from: overlayContent.nowSay))
        let spokenWords = normalizedWords(from: text)
        let overlapCount = spokenWords.filter { answerWords.contains($0) }.count
        let overlapThreshold = min(max(2, spokenWords.count / 3), 5)

        if overlapCount >= overlapThreshold || voiceActivityState == .speaking {
            return userDisplayName
        }

        return userSpeaker.isEmpty ? "You" : userDisplayName
    }

    private func normalizedSpeakerName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isLikelyOtherSpeaker(text: String) -> Bool {
        guard !text.isEmpty else { return false }

        if text.contains("?") {
            return true
        }

        let cues = [
            "can you",
            "could you",
            "what do you think",
            "how would you",
            "why would",
            "tell me",
            "walk me through",
            "help me understand"
        ]

        return cues.contains(where: text.contains)
    }

    private func isLikelyUserResponse(text: String) -> Bool {
        guard !text.isEmpty else { return false }

        let answerCues = [
            "i think",
            "i would",
            "we can",
            "we should",
            "the best next step",
            "the clearest answer",
            "the safest move",
            "my view is",
            "from my side",
            "what i would do"
        ]

        if answerCues.contains(where: text.contains) {
            return true
        }

        let answerWords = Set(normalizedWords(from: overlayContent.nowSay))
        let spokenWords = normalizedWords(from: text)
        guard !spokenWords.isEmpty else { return false }
        let overlapCount = spokenWords.filter { answerWords.contains($0) }.count
        return overlapCount >= min(max(3, spokenWords.count / 2), 6)
    }

    private func detectIntent(from text: String) -> LiveIntent {
        let lowered = text.lowercased()

        if lowered.contains("price") || lowered.contains("budget") || lowered.contains("cost") {
            return .pricing
        }
        if lowered.contains("concern") || lowered.contains("worried") || lowered.contains("risk") || lowered.contains("hard") || lowered.contains("problem") {
            return .objection
        }
        if lowered.contains("decide") || lowered.contains("decision") || lowered.contains("approve") || lowered.contains("move forward") {
            return .decision
        }
        if lowered.contains("prove") || lowered.contains("example") || lowered.contains("evidence") || lowered.contains("show me") {
            return .proof
        }
        if lowered.contains("next step") || lowered.contains("follow up") || lowered.contains("what next") {
            return .nextStep
        }
        if lowered.contains("?") || lowered.contains("how") || lowered.contains("why") || lowered.contains("what") {
            return .clarification
        }

        return .general
    }

    private func detectObjectionKind(from text: String) -> ObjectionKind {
        let lowered = text.lowercased()

        if lowered.contains("budget") || lowered.contains("cost") || lowered.contains("expensive") || lowered.contains("too much") {
            return .budget
        }
        if lowered.contains("later") || lowered.contains("timing") || lowered.contains("quarter") || lowered.contains("right now") || lowered.contains("not now") {
            return .timing
        }
        if lowered.contains("trust") || lowered.contains("security") || lowered.contains("reliable") || lowered.contains("prove") || lowered.contains("worked before") {
            return .trust
        }
        if lowered.contains("complex") || lowered.contains("complicated") || lowered.contains("implementation") || lowered.contains("integrate") {
            return .complexity
        }
        if lowered.contains("team") || lowered.contains("adoption") || lowered.contains("change") || lowered.contains("training") || lowered.contains("use it") {
            return .adoption
        }

        return .general
    }

    private func detectDecisionKind(from text: String) -> DecisionKind {
        let lowered = text.lowercased()

        if lowered.contains("approve") || lowered.contains("sign off") || lowered.contains("buy in") {
            return .approval
        }
        if lowered.contains("owner") || lowered.contains("who will") || lowered.contains("who owns") || lowered.contains("responsible") {
            return .owner
        }
        if lowered.contains("when") || lowered.contains("timeline") || lowered.contains("date") || lowered.contains("this month") || lowered.contains("this quarter") {
            return .timeline
        }
        if lowered.contains("pilot") || lowered.contains("trial") || lowered.contains("start small") || lowered.contains("test this") {
            return .pilot
        }

        return .general
    }

    private func guidanceConfidenceLevel(for request: ConversationRequest) -> GuidanceConfidence {
        confidenceAssessment(request: request).level
    }

    private func liveConversationRequest() -> ConversationRequest {
        ConversationRequest(
            configuration: configuration,
            transcriptSegments: liveContextSegments(),
            retrievalResults: retrievalResults
        )
    }

    private func liveContextSegments(maxSegments: Int = 4) -> [TranscriptSegment] {
        var selected: [TranscriptSegment] = []
        var seenFingerprints = Set<String>()

        for segment in transcriptSegments {
            guard segment.isFinal else { continue }

            let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let fingerprint = normalizedSpeakerName(segment.speaker) + "|" + trimmed.lowercased()
            guard !seenFingerprints.contains(fingerprint) else { continue }

            if let last = selected.last,
               normalizedSpeakerName(last.speaker) == normalizedSpeakerName(segment.speaker),
               normalizedWords(from: trimmed).count < normalizedWords(from: last.text).count {
                continue
            }

            seenFingerprints.insert(fingerprint)
            selected.append(segment)

            if selected.count >= maxSegments {
                break
            }
        }

        return selected
    }

    private func confidenceAssessment(request: ConversationRequest) -> ConfidenceAssessment {
        let latestQuestion = request.transcriptSegments.first(where: {
            normalizedSpeakerName($0.speaker) != normalizedSpeakerName(userDisplayName)
        })?.text ?? latestTranscriptText

        if manualInterruptionActive {
            return ConfidenceAssessment(
                level: .low,
                score: 18,
                summary: "Interruption active, so the answer should stay short and defensive."
            )
        }

        let otherSegments = request.transcriptSegments.filter {
            normalizedSpeakerName($0.speaker) != normalizedSpeakerName(userDisplayName)
        }
        let recentOtherSegments = Array(otherSegments.prefix(3))
        let latestQuestionTrimmed = latestQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalOtherCount = recentOtherSegments.filter(\.isFinal).count
        let averageConfidence = recentOtherSegments.isEmpty
            ? 0
            : recentOtherSegments.map(\.confidence).reduce(0, +) / Double(recentOtherSegments.count)
        let topRetrievalScore = request.retrievalResults.first?.score ?? 0
        let matchedTermsCount = request.retrievalResults.first?.matchedTerms.count ?? 0

        var score = 34
        var reasons: [String] = []

        if latestQuestionTrimmed.isEmpty || latestQuestionTrimmed == "Waiting for the latest question or context." {
            score -= 24
            reasons.append("no clear question yet")
        } else {
            score += 6
            reasons.append("question detected")
        }

        if isDirectQuestion(latestQuestionTrimmed) {
            score += 14
            reasons.append("direct ask")
        }

        if latestQuestionTrimmed.count >= 24 {
            score += 10
            reasons.append("enough detail")
        } else if latestQuestionTrimmed.count < 10 {
            score -= 8
            reasons.append("thin context")
        }

        if recentOtherSegments.count >= 2 {
            score += 10
            reasons.append("recent context")
        } else if recentOtherSegments.isEmpty {
            score -= 10
            reasons.append("single-thread context")
        }

        if finalOtherCount >= 2 {
            score += 10
            reasons.append("stable transcript")
        } else if finalOtherCount == 0 {
            score -= 12
            reasons.append("live transcript still unstable")
        }

        if averageConfidence >= 0.85 {
            score += 14
            reasons.append("strong transcript confidence")
        } else if averageConfidence >= 0.65 {
            score += 6
            reasons.append("usable transcript confidence")
        } else if averageConfidence > 0 {
            score -= 12
            reasons.append("weak transcript confidence")
        }

        if topRetrievalScore >= 0.45 {
            score += 12
            reasons.append("strong document match")
        } else if topRetrievalScore >= 0.2 {
            score += 6
            reasons.append("some supporting context")
        } else if !request.retrievalResults.isEmpty {
            reasons.append("light document support")
        }

        if matchedTermsCount >= 3 {
            score += 6
            reasons.append("good term overlap")
        }

        if voiceActivityState == .speaking && overlayState == .speaking {
            score -= 6
            reasons.append("mid-answer")
        }

        if overlayState == .recovery {
            score -= 8
            reasons.append("recovery mode")
        }

        if teleprompterProgress > 0.72 && overlayState == .speaking {
            score += 4
            reasons.append("answer nearly landed")
        }

        let clampedScore = max(0, min(100, score))
        let level: GuidanceConfidence
        switch clampedScore {
        case 72...:
            level = .high
        case 45...:
            level = .medium
        default:
            level = .low
        }

        let summary = reasons.isEmpty
            ? "Context is still forming."
            : reasons.prefix(3).joined(separator: ", ").capitalized + "."

        return ConfidenceAssessment(level: level, score: clampedScore, summary: summary)
    }

    private func guidanceStabilityReason(for segment: TranscriptSegment) -> String? {
        let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = normalizedWords(from: trimmed).count

        if segment.confidence > 0, segment.confidence < 0.42 {
            return "Waiting for clearer transcript"
        }

        if wordCount < 4 && !isDirectQuestion(trimmed) && detectIntent(from: trimmed) == .general {
            return "Waiting for more context"
        }

        let recentOtherTurns = transcriptSegments.filter {
            $0.isFinal && normalizedSpeakerName($0.speaker) != normalizedSpeakerName(userDisplayName)
        }

        if let previousTurn = recentOtherTurns.dropFirst().first {
            let previousWords = Set(normalizedWords(from: previousTurn.text))
            let currentWords = Set(normalizedWords(from: trimmed))
            let overlap = previousWords.intersection(currentWords).count
            let threshold = max(3, min(previousWords.count, currentWords.count) - 1)
            if overlap >= threshold {
                return "Waiting to avoid duplicate guidance"
            }
        }

        return nil
    }

    private func guidanceFingerprint(for segment: TranscriptSegment) -> String {
        let trimmed = segment.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let compactQuestion = normalizedWords(from: trimmed).prefix(10).joined(separator: " ")
        let intent = detectIntent(from: trimmed).rawValue
        return "\(meetingMode.rawValue)|\(intent)|\(compactQuestion)"
    }

    private func shapedPrimaryResponse(from text: String, confidence: GuidanceConfidence, intent: LiveIntent) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentence = firstSentence(in: trimmed)
        let interrupted = manualInterruptionActive
        let lowConfidence = confidence == .low

        func finalize(_ value: String) -> String {
            personalizedPrimaryResponse(from: value, confidence: confidence)
        }

        switch intent {
        case .objection:
            let base = sentence.isEmpty
                ? "That concern makes sense. The safest path is to reduce risk with one focused step first."
                : sentence
            switch currentObjectionKind {
            case .budget:
                if interrupted || lowConfidence {
                    return finalize("That makes sense. We can start smaller, prove value fast, and expand only if it earns the spend.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "We can reduce the starting scope, prove the outcome quickly, and only expand once the value is clear."
                ))
            case .timing:
                if interrupted || lowConfidence {
                    return finalize("That timing concern makes sense. The safest move is one smaller next step that fits the current window.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "We can keep momentum with one small step now instead of forcing the full rollout immediately."
                ))
            case .trust:
                if interrupted || lowConfidence {
                    return finalize("That concern makes sense. The safest move is to validate with one proof point or a low-risk next step first.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "We can de-risk this with one concrete proof point and a reversible next step before asking for more."
                ))
            case .complexity:
                if interrupted || lowConfidence {
                    return finalize("That makes sense. The best next step is to keep the path simple and start with the least disruptive move.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "We can simplify the first step, avoid extra change, and prove the workflow before expanding."
                ))
            case .adoption:
                if interrupted || lowConfidence {
                    return finalize("That is fair. The safest move is to start with a small group and make adoption easy before scaling.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "We can begin with a small team, support adoption closely, and expand only once usage becomes easy."
                ))
            case .general:
                if interrupted || lowConfidence {
                    return finalize("That concern makes sense. The safest next step is to keep the scope small and reduce risk first.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "We can keep the scope small, prove value quickly, and expand only after it works."
                ))
            }
        case .decision:
            let base = sentence.isEmpty
                ? "The best next move is to make the next commitment small and clear."
                : sentence
            switch currentDecisionKind {
            case .approval:
                if interrupted || lowConfidence {
                    return finalize("The best next move is to ask for one small approval that moves this forward now.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "If this makes sense, we should define the exact approval needed and make that decision easy to say yes to."
                ))
            case .owner:
                if interrupted || lowConfidence {
                    return finalize("The next move is to name one owner and one action so this does not stay vague.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "If this direction is right, the next step is to lock one owner, one action, and one date now."
                ))
            case .timeline:
                if interrupted || lowConfidence {
                    return finalize("The next move is to agree on one concrete date and the smallest step needed to protect it.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "If this is moving forward, we should anchor the next date now and back into the smallest step required."
                ))
            case .pilot:
                if interrupted || lowConfidence {
                    return finalize("The best next move is to frame this as a small pilot with a clear owner and success goal.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "If this makes sense, the next step is to lock a focused pilot with an owner, timing, and success signal."
                ))
            case .general:
                if interrupted || lowConfidence {
                    return finalize("The best next move is to make the next step small, clear, and easy to own now.")
                }
                return finalize(ensureTwoSentenceShape(
                    primary: base,
                    followUp: "If this direction makes sense, the next step is to lock the owner and timing now."
                ))
            }
        case .pricing:
            let base = sentence.isEmpty
                ? "The right way to think about price is through the starting scope and the value we need to prove first."
                : sentence
            if interrupted || lowConfidence {
                return finalize("The best way to frame price is through the starting scope and the value we need to prove first.")
            }
            return finalize(ensureTwoSentenceShape(
                primary: base,
                followUp: "We should size the first rollout around the smallest team that can validate the outcome."
            ))
        case .nextStep:
            let base = sentence.isEmpty
                ? "The clearest answer is to leave this meeting with one specific next step."
                : sentence
            if interrupted || lowConfidence {
                return finalize("The clearest answer is to leave with one specific next step, one owner, and one timeline.")
            }
            return finalize(ensureTwoSentenceShape(
                primary: base,
                followUp: "Let us make that next step concrete with an owner, timeline, and expected outcome."
            ))
        case .proof:
            let base = sentence.isEmpty
                ? "The clearest way to answer that is with one concrete proof point."
                : sentence
            if interrupted || lowConfidence {
                return finalize("The clearest way to answer that is with one concrete proof point tied to the result they care about.")
            }
            return finalize(ensureTwoSentenceShape(
                primary: base,
                followUp: "The important thing is to connect the example directly to the result they care about."
            ))
        case .clarification, .general:
            break
        }

        guard confidence == .low else { return finalize(trimmed) }

        if trimmed.isEmpty {
            return finalize("The short answer is to confirm the goal, give the safest next step, and clarify what matters most.")
        }

        return finalize(sentence.hasSuffix(".") ? sentence : sentence + ".")
    }

    private func shapedReason(from text: String, confidence: GuidanceConfidence, intent: LiveIntent) -> String {
        if manualInterruptionActive {
            return "You were interrupted, so the answer is intentionally shorter and safer to help you re-enter cleanly."
        }

        switch intent {
        case .objection:
            return "Treat this like a risk-reduction moment: acknowledge concern, simplify scope, and avoid arguing."
        case .decision:
            return "Treat this like a commitment moment: make the move small, clear, and easy to own."
        case .pricing:
            return "Treat this like a value-and-scope conversation, not a raw price defense."
        case .nextStep:
            return "Treat this like a closing moment: leave with one specific next action."
        case .proof:
            return "Treat this like a proof moment: use one concrete example instead of broad explanation."
        case .clarification, .general:
            guard confidence == .low else { return text }
            return "Context is still limited, so this keeps the answer safe, short, and easy to defend."
        }
    }

    private func shapedNextStep(from text: String, intent: LiveIntent) -> String {
        if manualInterruptionActive {
            return "Re-enter with one short sentence, then confirm the exact point they want next."
        }

        switch intent {
        case .objection:
            return "Ask what feels riskiest or hardest from their side right now."
        case .decision:
            return "Ask whether they are comfortable locking the owner and timing for the next step."
        case .pricing:
            return "Ask what initial team size or budget range they want to start with."
        case .nextStep:
            return "Ask who owns the next step, what date it happens, and what success looks like."
        case .proof:
            return "Ask whether they want a concrete example, a customer proof point, or a short walkthrough."
        case .clarification, .general:
            return personalizedNextStep(from: text)
        }
    }

    private func personalizedPrimaryResponse(from text: String, confidence: GuidanceConfidence) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        switch confidenceMode {
        case "safe":
            if confidence == .high {
                return trimmed
            }
            let first = firstSentence(in: trimmed)
            return first.hasSuffix(".") ? first : first + "."
        case "assertive":
            if trimmed.lowercased().hasPrefix("we can ") {
                return "The best next step is to " + trimmed.dropFirst(7)
            }
            return trimmed
        case "consultative":
            if confidence != .high {
                return trimmed
            }
            return ensureTwoSentenceShape(
                primary: trimmed,
                followUp: "That keeps the answer collaborative while we confirm what matters most."
            )
        default:
            return trimmed
        }
    }

    private func personalizedNextStep(from text: String) -> String {
        switch confidenceMode {
        case "safe":
            return "Ask one short clarifying question before committing further."
        case "assertive":
            return text.isEmpty ? "Ask for one clear next step, one owner, and one date." : text
        case "consultative":
            return "Ask what matters most to them before taking the next step."
        default:
            return text
        }
    }

    private func ensureTwoSentenceShape(primary: String, followUp: String) -> String {
        let first = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        let second = followUp.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstSentence = first.hasSuffix(".") ? first : first + "."
        let secondSentence = second.hasSuffix(".") ? second : second + "."
        return "\(firstSentence) \(secondSentence)"
    }

    private func firstSentence(in text: String) -> String {
        text
            .split(separator: ".")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? text
    }

    private func shouldUseRecoveryMode(for segment: TranscriptSegment) -> Bool {
        guard normalizedSpeakerName(segment.speaker) != normalizedSpeakerName(userDisplayName) else {
            return false
        }

        let text = segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }

        if isDirectQuestion(text) {
            return true
        }

        if let previousUserTurn = transcriptSegments.first(where: {
            normalizedSpeakerName($0.speaker) == normalizedSpeakerName(userDisplayName)
        }) {
            let gap = segment.createdAt.timeIntervalSince(previousUserTurn.createdAt)
            if gap > 45, isLikelyDecisionMoment(text) {
                return true
            }
        }

        return false
    }

    private func applyRecoveryMode(for segment: TranscriptSegment) {
        let summary = summarizeForRecovery(segment.text)
        let want = inferAskIntent(from: segment.text)

        overlayContent = OverlayContent(
            nowSay: safeRecoveryAnswer(for: segment.text),
            why: "What happened: \(summary) || They need: \(want)",
            next: followUpPrompt(for: segment.text)
        )
        overlayState = .recovery
        guidanceConfidence = .low
        conversationModeLabel = "Recovery mode"
        liveResponseState = "Recovery answer ready"
        providerStatusMessage = "Using recovery fallback"
        appendLog("Triggered Smart Recovery Mode")
    }

    private func templateOverlayContent(for mode: MeetingMode) -> OverlayContent {
        switch mode {
        case .sales:
            return OverlayContent(
                nowSay: "Start with the lowest-risk next step, prove value quickly, and expand from evidence.",
                why: "Keeps the answer commercial, direct, and outcome-focused.",
                next: "Ask what would need to be true for them to start a pilot."
            )
        case .demo:
            return OverlayContent(
                nowSay: "Frame the answer around the workflow improvement they will notice first, then show the next relevant step.",
                why: "Keeps the demo grounded in user value instead of feature depth.",
                next: "Ask which workflow they want to see next."
            )
        case .clientReview:
            return OverlayContent(
                nowSay: "Anchor on progress, current risk, and the clearest next action so the client feels guided and informed.",
                why: "Helps the conversation feel calm, accountable, and strategic.",
                next: "Ask which risk or milestone matters most before the next review."
            )
        case .interview:
            return OverlayContent(
                nowSay: "Lead with the direct answer, connect it to an outcome, and use one tight example if they want depth.",
                why: "Keeps the answer structured without sounding rehearsed.",
                next: "Ask if they want the short summary or a deeper example."
            )
        case .internalSync:
            return OverlayContent(
                nowSay: "Clarify the decision, name the owner, and keep the next step specific.",
                why: "Moves internal meetings toward alignment and action instead of drift.",
                next: "Ask who owns the next step and what could block it."
            )
        case .general:
            return OverlayContent(
                nowSay: "Give the clearest short answer first, then add only the detail that helps the decision.",
                why: "Keeps the conversation moving without over-explaining.",
                next: "Ask one focused follow-up to confirm what matters most."
            )
        }
    }

    private func summarizeForRecovery(_ text: String) -> String {
        let compact = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !compact.isEmpty else {
            return "The conversation turned back to you."
        }

        let summary = compact
            .split(whereSeparator: \.isWhitespace)
            .prefix(14)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return summary.hasSuffix(".") ? summary : summary + "."
    }

    private func inferAskIntent(from text: String) -> String {
        switch detectIntent(from: text) {
        case .pricing:
            return "They want a clear view on pricing or rollout size."
        case .objection:
            return "They need risk reduction, confidence, or a simpler path forward."
        case .decision:
            return "They want enough clarity to decide whether to move forward."
        case .proof:
            return "They want evidence, examples, or proof that the approach will work."
        case .nextStep:
            return "They want the clearest next move and who should own it."
        case .clarification:
            let lowered = text.lowercased()
            if lowered.contains("timeline") || lowered.contains("when") {
                return "They want timing clarity and the safest next step."
            }
            if lowered.contains("how") {
                return "They want the practical approach, not a long explanation."
            }
            if lowered.contains("why") {
                return "They want reasoning and confidence in the recommendation."
            }
            return "They want a direct answer and one clear next move."
        case .general:
            let lowered = text.lowercased()
            if lowered.contains("timeline") || lowered.contains("when") {
            return "They want timing clarity and the safest next step."
            }
            return "They want a direct answer and one clear next move."
        }
    }

    private func safeRecoveryAnswer(for text: String) -> String {
        switch detectIntent(from: text) {
        case .pricing:
            return "The simplest answer is to start with the right initial scope, prove value quickly, and size the rollout from there."
        case .objection:
            return "The safest answer is to reduce risk first, keep the rollout focused, and validate with one practical step."
        case .decision:
            return "The best answer is to make the next decision small, clear, and easy to act on now."
        case .proof:
            return "The clearest answer is to tie this to one concrete example, one real outcome, and one simple next step."
        case .nextStep:
            return "The practical answer is to agree on one clear next step, one owner, and one timeline."
        case .clarification:
            let lowered = text.lowercased()
            if lowered.contains("timeline") || lowered.contains("when") {
            return "The safest path is to begin with one focused step now, validate quickly, and expand once the team sees traction."
            }
            if lowered.contains("how") {
                return "The practical answer is to keep it simple first, confirm the goal, and then go deeper only where it helps."
            }
            return "The short answer is to take the lowest-risk next step first, confirm the outcome, and then build from there."
        case .general:
            return "The short answer is to take the lowest-risk next step first, confirm the outcome, and then build from there."
        }
    }

    private func followUpPrompt(for text: String) -> String {
        switch detectIntent(from: text) {
        case .pricing:
            return "Ask what budget range or first-team size they are considering."
        case .objection:
            return "Ask what feels riskiest or hardest from their side right now."
        case .decision:
            return "Ask what would need to be true for them to move forward."
        case .proof:
            return "Ask whether they want an example, evidence, or a deeper walkthrough."
        case .nextStep:
            return "Ask who should own the next step and by when."
        case .clarification:
            let lowered = text.lowercased()
            if lowered.contains("timeline") || lowered.contains("when") {
                return "Ask what deadline or launch window matters most."
            }
            if lowered.contains("how") {
            return "Ask whether they want the short version or the implementation detail."
            }
            return "Ask one clarifying question to confirm what matters most."
        case .general:
            return "Ask one clarifying question to confirm what matters most."
        }
    }

    private func isDirectQuestion(_ text: String) -> Bool {
        let lowered = text.lowercased()
        if lowered.contains("?") {
            return true
        }

        let cues = [
            "can you",
            "could you",
            "would you",
            "what do you think",
            "how would you",
            "what's your view",
            "tell us",
            "walk us through"
        ]

        return cues.contains(where: lowered.contains)
    }

    private func isLikelyDecisionMoment(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let cues = [
            "next step",
            "rollout",
            "budget",
            "price",
            "timeline",
            "pilot",
            "decision"
        ]
        return cues.contains(where: lowered.contains)
    }

    private func recoveryDetailParts() -> (summary: String, need: String) {
        let raw = overlayContent.why
        let parts = raw.components(separatedBy: " || ")

        let summary = parts.first?
            .replacingOccurrences(of: "What happened:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let need = parts.dropFirst().first?
            .replacingOccurrences(of: "They need:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (
            summary: summary?.isEmpty == false ? summary! : overlayContent.why,
            need: need?.isEmpty == false ? need! : "A direct answer and a clear next move."
        )
    }

    private func syncOverlayStateFromLiveSignals() {
        let now = Date()

        if manualInterruptionActive || isPaused {
            overlayState = .paused
            return
        }

        if let clearedAt = lastInterruptionClearedAt,
           now.timeIntervalSince(clearedAt) < 1.4,
           audioCaptureState == .capturing {
            overlayState = overlayContent.nowSay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .listening : .answerReady
            interruptionState = "Re-entering"
            return
        }

        if teleprompterProgress >= 0.75 && voiceActivityState == .silent {
            overlayState = .postAnswer
            if lastAnswerCompletionAt == nil {
                lastAnswerCompletionAt = now
            }
            return
        }

        if let completedAt = lastAnswerCompletionAt,
           now.timeIntervalSince(completedAt) < 1.5,
           voiceActivityState == .silent {
            overlayState = .postAnswer
            interruptionState = "Answer landed"
            return
        } else if let completedAt = lastAnswerCompletionAt,
                  now.timeIntervalSince(completedAt) >= 1.5 {
            lastAnswerCompletionAt = nil
        }

        if teleprompterProgress > 0.08 && voiceActivityState == .speaking {
            overlayState = .speaking
            interruptionState = "Following your answer"
            return
        }

        if let speakingAt = lastSpeakingActivityAt,
           now.timeIntervalSince(speakingAt) < 0.7,
           teleprompterProgress > 0.08 {
            overlayState = .speaking
            interruptionState = "Holding your answer"
            return
        }

        if overlayState == .recovery {
            return
        }

        if let detectedAt = lastQuestionDetectedAt,
           now.timeIntervalSince(detectedAt) < 0.9,
           voiceActivityState == .silent {
            overlayState = .questionDetected
            interruptionState = "Reading the question"
            return
        }

        if let otherTurnAt = lastOtherSpeakerTurnAt,
           now.timeIntervalSince(otherTurnAt) < 1.1,
           voiceActivityState == .silent,
           teleprompterProgress < 0.08 {
            overlayState = .questionDetected
            interruptionState = "Fresh question"
            return
        }

        if !overlayContent.nowSay.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           transcriptSegments.contains(where: { normalizedSpeakerName($0.speaker) != normalizedSpeakerName(userDisplayName) }) {
            overlayState = .answerReady
            interruptionState = "Ready to answer"
            return
        }

        interruptionState = audioCaptureState == .capturing ? "Listening" : "Idle"
        overlayState = audioCaptureState == .capturing ? .listening : .idle
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

    private func dependencyStatus(for id: String) -> DependencyStatus {
        dependencyItems.first(where: { $0.id == id })?.status ?? .pending
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
