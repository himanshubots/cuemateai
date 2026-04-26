import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch model.selectedSection ?? .live {
                    case .live:
                        StartSessionWorkspaceView(model: model)
                    case .review:
                        HistoryWorkspaceView(model: model)
                    case .setup, .settings:
                        SettingsWorkspaceView(model: model)
                    }
                }
                .padding(24)
                .frame(maxWidth: 1100, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var topBar: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cuemate")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Clean live help for meetings, demos, and client calls.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                navPill(for: .live, icon: "play.circle.fill")
                navPill(for: .review, icon: "clock.arrow.circlepath")
                navPill(for: .setup, icon: "gearshape.fill")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private func navPill(for section: AppModel.WorkspaceSection, icon: String) -> some View {
        Button {
            model.selectedSection = section
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(section.title)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(model.selectedSection == section ? Color.accentColor.opacity(0.16) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(model.selectedSection == section ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct StartSessionWorkspaceView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WorkspaceHeroCard(
                eyebrow: "Start Session",
                title: "Stay ready when the room turns to you.",
                subtitle: "Keep the live view simple: start the session, show the overlay, listen, and get a short response with context and one next action."
            )

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    sessionCard
                    preMeetingBriefCard
                    recurringMemoryCard
                    readinessCard
                    liveControlCard
                    currentGuidanceCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 20) {
                    transcriptCard
                    coachingCard
                    riskFlagsCard
                    playbookCard
                    activityStatusCard
                }
                .frame(width: 360, alignment: .top)
            }
        }
    }

    private var sessionCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Session")
                            .font(.title3.weight(.semibold))
                        Text(model.activeMeetingSession?.title ?? "Create a live session before the meeting starts.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusDot(
                        title: model.activeMeetingSession == nil ? "Idle" : "Live",
                        color: model.activeMeetingSession == nil ? .gray : .green
                    )
                }

                HStack(spacing: 12) {
                    TextField("Session name", text: $model.sessionDraftTitle)
                        .textFieldStyle(.roundedBorder)

                    Picker("Type", selection: Binding(
                        get: { model.meetingMode },
                        set: { model.applyMeetingMode($0) }
                    )) {
                        ForEach(MeetingMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }

                Text(model.meetingMode.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ActionButton(
                        title: model.activeMeetingSession == nil ? "Start Session" : "Update Session",
                        systemImage: "play.fill",
                        tint: .green
                    ) {
                        model.startMeetingSession()
                    }

                    ActionButton(
                        title: model.activeMeetingSession == nil ? "Show Overlay" : "End Session",
                        systemImage: model.activeMeetingSession == nil ? "rectangle.on.rectangle.circle" : "stop.fill",
                        tint: model.activeMeetingSession == nil ? .blue : .red
                    ) {
                        if model.activeMeetingSession == nil {
                            if !model.overlayVisible {
                                model.toggleOverlay()
                            }
                        } else {
                            model.endMeetingSession()
                        }
                    }
                }

                if let session = model.activeMeetingSession {
                    HStack(spacing: 14) {
                        CompactMetric(title: "Transcript", value: "\(session.transcriptSegments.count)")
                        CompactMetric(title: "Guidance", value: "\(session.guidanceHistory.count)")
                        CompactMetric(title: "Provider", value: providerLabel(model.generationProvider))
                    }
                }
            }
        }
    }

    private var liveControlCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Live Controls")
                    .font(.title3.weight(.semibold))

                HStack(spacing: 12) {
                    ActionButton(
                        title: model.audioCaptureState == .capturing ? "Stop Listening" : "Start Listening",
                        systemImage: model.audioCaptureState == .capturing ? "mic.slash.fill" : "mic.fill",
                        tint: model.audioCaptureState == .capturing ? .red : .orange
                    ) {
                        if model.audioCaptureState == .capturing {
                            model.stopMicrophoneCapture()
                        } else {
                            Task {
                                await model.requestSpeechAccess()
                                await model.requestMicrophoneAccessAndStart()
                            }
                        }
                    }

                    ActionButton(
                        title: model.overlayVisible ? "Hide Overlay" : "Show Overlay",
                        systemImage: model.overlayVisible ? "eye.slash.fill" : "eye.fill",
                        tint: .blue
                    ) {
                        model.toggleOverlay()
                    }

                    ActionButton(
                        title: "Refresh Response",
                        systemImage: "sparkles",
                        tint: .purple
                    ) {
                        Task {
                            await model.generateConversationGuidance()
                        }
                    }

                    ActionButton(
                        title: "Buy Time",
                        systemImage: "hourglass",
                        tint: .mint
                    ) {
                        model.generateBuyTimeGuidance()
                    }

                    ActionButton(
                        title: model.isPaused ? "Resume" : "Pause",
                        systemImage: model.isPaused ? "play.fill" : "pause.fill",
                        tint: .gray
                    ) {
                        model.togglePause()
                    }
                }

                HStack(spacing: 16) {
                    StatusDot(title: stateLabel(model.audioCaptureState), color: model.audioCaptureState == .capturing ? .green : .gray)
                    StatusDot(title: model.overlayStatusSummary, color: overlayStateColor(model.overlayState))
                    StatusDot(title: model.guidanceConfidence.title, color: confidenceColor(model.guidanceConfidence))
                    StatusDot(title: model.liveDecisionCue, color: liveDecisionColor(model.liveDecisionCue))
                    StatusDot(title: model.liveResponseState, color: .orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Steering")
                        .font(.subheadline.weight(.semibold))

                    HStack(spacing: 10) {
                        quickStyleButton(title: "Balanced", active: model.confidenceMode == "balanced") {
                            model.setPreferredResponseStyle("balanced")
                        }
                        quickStyleButton(title: "Safe", active: model.confidenceMode == "safe") {
                            model.setPreferredResponseStyle("safe")
                        }
                        quickStyleButton(title: "Assertive", active: model.confidenceMode == "assertive") {
                            model.setPreferredResponseStyle("assertive")
                        }
                        quickStyleButton(title: "Consultative", active: model.confidenceMode == "consultative") {
                            model.setPreferredResponseStyle("consultative")
                        }
                    }
                }
            }
        }
    }

    private func quickStyleButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(active ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(active ? Color.accentColor.opacity(0.4) : Color.black.opacity(0.06), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var preMeetingBriefCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pre-Meeting Brief")
                            .font(.title3.weight(.semibold))
                        Text("A quick role-aware prep view before the meeting starts.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusDot(title: model.meetingMode.title, color: .blue)
                }

                if let brief = model.activeMeetingSession?.brief {
                    PreSessionBriefView(brief: brief)
                        .frame(maxHeight: 420)
                } else {
                    ForEach(model.preMeetingBriefItems, id: \.self) { item in
                        BulletLine(text: item)
                    }
                }
            }
        }
    }

    private var readinessCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Meeting Readiness")
                            .font(.title3.weight(.semibold))
                        Text("A quick check before you go live.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusDot(title: model.setupReadiness.title, color: readinessColor(model.setupReadiness))
                }

                ForEach(model.setupChecklistItems, id: \.title) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.done ? Color.green : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var recurringMemoryCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recurring Memory")
                            .font(.title3.weight(.semibold))
                        Text("Small continuity from recent sessions of the same meeting type.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusDot(title: model.meetingMode.title, color: .mint)
                }

                ForEach(model.recurringMemoryItems, id: \.self) { item in
                    BulletLine(text: item)
                }
            }
        }
    }

    private var currentGuidanceCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Overlay Output")
                            .font(.title3.weight(.semibold))
                        Text("This is the same structure shown in the live overlay, including recovery and safe fallback states.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(model.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                        model.toggleOverlay()
                    }
                    .buttonStyle(.bordered)
                }

                OverlayPanelView(model: model)
                    .frame(maxWidth: 520, alignment: .leading)

                if model.teleprompterProgress > 0.08 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Response Progress")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("\(Int(model.teleprompterProgress * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: model.teleprompterProgress)
                    }
                }
            }
        }
    }

    private var transcriptCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Recent Transcript")
                    .font(.title3.weight(.semibold))

                if model.transcriptSegments.isEmpty {
                    EmptyStateCard(text: "Start listening to see the latest conversation here.")
                } else {
                    ForEach(model.transcriptSegments.prefix(6)) { segment in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(segment.speaker)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(segment.speaker == model.userDisplayName ? Color.accentColor : .secondary)
                                Spacer()
                                Text(segment.isFinal ? "Final" : "Live")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(segment.text)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }
                }
            }
        }
    }

    private var activityStatusCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Live Status")
                    .font(.title3.weight(.semibold))

                CompactMetric(title: "Speaker", value: model.userDisplayName)
                CompactMetric(title: "Other Role", value: model.collaboratorRoleLabel)
                CompactMetric(title: "Speaker Read", value: model.speakerReadSummary)
                CompactMetric(title: "Transcription", value: model.transcriptionProvider.title)
                CompactMetric(title: "Response", value: providerLabel(model.generationProvider))
                CompactMetric(title: "Intent", value: model.detectedIntent.title)
                CompactMetric(title: "Moment", value: model.liveMomentLabel)
                CompactMetric(title: "Mode", value: model.suggestedResponseMode.title)
                CompactMetric(title: "Signal", value: model.confidenceScoreLabel)
                CompactMetric(title: "Voice", value: model.voiceActivityState.rawValue.capitalized)
            }
        }
    }

    private var coachingCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Coach")
                    .font(.title3.weight(.semibold))

                DetailBlock(title: "Mode Focus", text: model.meetingModeFocusSummary)
                DetailBlock(title: "Suggested Mode", text: model.suggestedResponseMode.title)
                DetailBlock(title: "Preferred Style", text: model.preferredResponseStyleTitle)
                DetailBlock(title: "Cue", text: model.coachingCue)
                DetailBlock(title: "Confidence Advice", text: model.confidenceAdvice)
                DetailBlock(title: "Signal Read", text: model.confidenceSignalSummary)
                DetailBlock(title: "Context Read", text: model.liveContextSummary)
                if let step = model.interruptionRecoveryStep {
                    DetailBlock(title: "Re-entry", text: step)
                }
            }
        }
    }

    private var playbookCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(model.activePlaybookTitle)
                    .font(.title3.weight(.semibold))

                DetailBlock(title: "Current Moment", text: model.liveMomentLabel)

                ForEach(model.activePlaybookSteps) { step in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.subheadline.weight(.semibold))
                        Text(step.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }

                DetailBlock(title: "Mode Risk", text: model.meetingModeRiskSummary)
                DetailBlock(title: "Avoid", text: model.playbookRiskToAvoid)
            }
        }
    }

    private var riskFlagsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Watchouts")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    StatusDot(title: model.liveRiskFlags.isEmpty ? "Stable" : "Active", color: model.liveRiskFlags.isEmpty ? .green : .orange)
                }

                if model.liveRiskFlags.isEmpty {
                    EmptyStateCard(text: "No active watchouts right now. The live read looks stable.")
                } else {
                    ForEach(model.liveRiskFlags, id: \.self) { flag in
                        BulletLine(text: flag)
                    }
                }
            }
        }
    }

    private func stateLabel(_ state: AudioCaptureState) -> String {
        switch state {
        case .idle: "Mic idle"
        case .requestingPermission: "Requesting mic"
        case .ready: "Mic ready"
        case .capturing: "Listening"
        case .denied: "Mic denied"
        case .failed: "Mic failed"
        }
    }

    private func providerLabel(_ provider: GenerationProvider) -> String {
        switch provider {
        case .localHeuristic: "Local"
        case .openAI: "OpenAI"
        case .ollama: "Ollama"
        }
    }

    private func overlayStateColor(_ state: OverlayState) -> Color {
        switch state {
        case .recovery: .yellow
        case .answerReady: .blue
        case .speaking: .mint
        case .postAnswer: .green
        case .paused: .orange
        case .questionDetected: .purple
        case .listening, .idle: .gray
        }
    }

    private func confidenceColor(_ confidence: GuidanceConfidence) -> Color {
        switch confidence {
        case .low: .yellow
        case .medium: .blue
        case .high: .green
        }
    }

    private func liveDecisionColor(_ cue: String) -> Color {
        switch cue {
        case "Stop": .green
        case "Close": .blue
        case "Clarify": .yellow
        case "Reduce Risk": .orange
        case "Re-enter": .pink
        default: .secondary
        }
    }

    private func readinessColor(_ readiness: SetupReadiness) -> Color {
        switch readiness {
        case .needsSetup: .red
        case .partial: .yellow
        case .ready: .green
        }
    }
}

struct HistoryWorkspaceView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WorkspaceHeroCard(
                eyebrow: "History",
                title: "Review past sessions without the clutter.",
                subtitle: "Every saved session keeps the transcript, live guidance, and post-meeting summary in one place."
            )

            SurfaceCard {
                if model.historyState.sessions.isEmpty {
                    EmptyStateCard(text: "No saved sessions yet.")
                } else {
                    SessionHistoryView(
                        sessions: model.historyState.sessions,
                        documents: model.historyState.documents
                    )
                    .frame(minHeight: 620)
                }
            }
        }
    }
}

struct SettingsWorkspaceView: View {
    @ObservedObject var model: AppModel
    @State private var openAIKeyInput = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            WorkspaceHeroCard(
                eyebrow: "Settings",
                title: "Setup once, then keep it out of the way.",
                subtitle: "This page handles first-time setup, provider choices, your speaker name, and overlay placement."
            )

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 20) {
                    setupReadinessCard
                    setupCard
                    providerCard
                    privacyCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 20) {
                    identityCard
                    overlayCard
                }
                .frame(width: 360, alignment: .top)
            }
        }
        .onAppear {
            openAIKeyInput = model.openAIKeyPresent ? "Saved in Keychain" : ""
        }
    }

    private var setupCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("First-Time Setup")
                            .font(.title3.weight(.semibold))
                        Text("Check local runtime and install only what you need.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Refresh") {
                        Task {
                            await model.refreshDependencyStatuses()
                        }
                    }
                    .buttonStyle(.bordered)
                }

                ForEach(model.dependencyItems) { item in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.descriptor.title)
                                .font(.headline)
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(statusLabel(item.status))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor(item.status))
                        if item.status != .ready {
                            Button(actionTitle(for: item)) {
                                Task {
                                    await model.performInstall(for: item.id)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }
            }
        }
    }

    private var setupReadinessCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended Setup")
                            .font(.title3.weight(.semibold))
                        Text("Use the safest defaults for this machine and workflow.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusDot(title: model.setupReadiness.title, color: readinessColor(model.setupReadiness))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended transcription: \(model.recommendedTranscriptionProvider.title)")
                    Text("Recommended response: \(providerLabel(model.recommendedGenerationProvider))")
                }
                .font(.subheadline)

                Button("Apply Recommended Defaults") {
                    model.applyRecommendedSetupDefaults()
                }
                .buttonStyle(.borderedProminent)

                ForEach(model.setupChecklistItems, id: \.title) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.done ? Color.green : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                            Text(item.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var providerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Providers")
                    .font(.title3.weight(.semibold))

                Picker("Transcription", selection: $model.transcriptionProvider) {
                    ForEach(TranscriptionProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Response", selection: $model.generationProvider) {
                    ForEach(GenerationProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Auto-refresh response from final transcript", isOn: $model.autoResponseEnabled)

                SecureField("OpenAI API key (optional)", text: $openAIKeyInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save OpenAI Key") {
                        model.saveOpenAIKey(openAIKeyInput == "Saved in Keychain" ? "" : openAIKeyInput)
                    }
                    .buttonStyle(.borderedProminent)

                    if model.openAIKeyPresent {
                        Button("Remove Key") {
                            openAIKeyInput = ""
                            model.saveOpenAIKey("")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }

    private var identityCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Identity")
                    .font(.title3.weight(.semibold))

                TextField("Your name", text: $model.configuration.speakerName)
                    .textFieldStyle(.roundedBorder)

                Picker("Meeting type", selection: $model.configuration.meetingType) {
                    ForEach(MeetingMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Button("Apply Meeting Template") {
                    model.applyMeetingMode(model.meetingMode)
                }
                .buttonStyle(.bordered)

                Picker("Preferred answer style", selection: $model.confidenceMode) {
                    Text("Balanced").tag("balanced")
                    Text("Safe").tag("safe")
                    Text("Assertive").tag("assertive")
                    Text("Consultative").tag("consultative")
                }
                .pickerStyle(.segmented)

                Text(model.preferredResponseStyleSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Click through overlay", isOn: Binding(
                    get: { model.clickThroughEnabled },
                    set: { model.setClickThrough($0) }
                ))
            }
        }
    }

    private var privacyCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy And Data")
                            .font(.title3.weight(.semibold))
                        Text("See what stays local, what can leave the machine, and what gets stored.")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusDot(
                        title: model.generationProvider == .openAI ? "External API" : "Local-First",
                        color: model.generationProvider == .openAI ? .orange : .green
                    )
                }

                DetailBlock(title: "Response Path", text: model.privacyExecutionSummary)
                DetailBlock(title: "Transcription Path", text: model.privacyTranscriptionSummary)
                DetailBlock(title: "Current Provider Status", text: model.providerStatusMessage)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Stored Locally")
                        .font(.subheadline.weight(.semibold))
                    ForEach(model.privacyStorageItems, id: \.self) { item in
                        BulletLine(text: item)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Boundaries")
                        .font(.subheadline.weight(.semibold))
                    ForEach(model.privacyBoundaryItems, id: \.self) { item in
                        BulletLine(text: item)
                    }
                }
            }
        }
    }

    private var overlayCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Overlay Position")
                    .font(.title3.weight(.semibold))

                Picker("Anchor", selection: $model.overlayAnchor) {
                    ForEach(OverlayAnchor.allCases) { anchor in
                        Text(anchor.title).tag(anchor)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Horizontal")
                        .font(.caption.weight(.semibold))
                    Slider(value: $model.overlayHorizontalInset, in: -180...180, step: 1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Vertical")
                        .font(.caption.weight(.semibold))
                    Slider(value: $model.overlayVerticalInset, in: -40...180, step: 1)
                }

                Button("Apply Overlay Position") {
                    model.pinOverlayNearCamera()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func statusLabel(_ status: DependencyStatus) -> String {
        switch status {
        case .ready: "Ready"
        case .missing: "Missing"
        case .optional: "Optional"
        case .pending: "Checking"
        case .installing: "Installing"
        case .failed: "Failed"
        }
    }

    private func statusColor(_ status: DependencyStatus) -> Color {
        switch status {
        case .ready: .green
        case .missing, .failed: .red
        case .optional, .pending: .secondary
        case .installing: .orange
        }
    }

    private func actionTitle(for item: InstallerItemViewModel) -> String {
        item.status == .installing ? "Installing..." : item.descriptor.installActionTitle
    }

    private func providerLabel(_ provider: GenerationProvider) -> String {
        switch provider {
        case .localHeuristic: "Local"
        case .openAI: "OpenAI"
        case .ollama: "Ollama"
        }
    }

    private func readinessColor(_ readiness: SetupReadiness) -> Color {
        switch readiness {
        case .needsSetup: .red
        case .partial: .yellow
        case .ready: .green
        }
    }
}

struct OverlayPanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                StatusDot(
                    title: model.overlayStatusSummary,
                    color: overlayStateColor
                )
                Spacer()
                HStack(spacing: 10) {
                    Text(model.detectedIntent.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                    Text(model.guidanceConfidence.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }

            if model.overlayState == .recovery && model.guidanceConfidence == .low {
                recoveryHero
            }

            overlayBlock(title: "Question", body: model.latestQuestionText, style: .secondary)
            overlayBulletBlock(title: "Points", body: model.liveResponseText)
            if let summary = model.recoverySummaryText {
                overlayBlock(title: "What Happened", body: summary, style: .muted)
            }
            if let need = model.recoveryNeedText {
                overlayBlock(title: "They Need", body: need, style: .muted)
            } else {
                overlayBlock(title: "Context", body: model.latestContextText, style: .muted)
            }
            overlayBlock(title: "Action", body: model.overlayActionText, style: .accent)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.09, green: 0.11, blue: 0.14).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var recoveryHero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quick Recovery")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.yellow.opacity(0.9))
            Text("Use the short answer first. Do not over-explain. Ask one clarifying question right after.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.yellow.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.yellow.opacity(0.25), lineWidth: 1)
        )
    }

    private func overlayBlock(title: String, body: String, style: OverlayLineStyle) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.55))
            Text(body)
                .font(style == .secondary ? .callout : .subheadline.weight(style == .accent ? .semibold : .regular))
                .foregroundStyle(style.color)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(style == .muted ? 2 : nil)
        }
    }

    private func overlayBulletBlock(title: String, body: String) -> some View {
        let points = compactPoints(from: body)

        return VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.55))

            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)
                    Text(point)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func compactPoints(from text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ["Waiting for guidance."] }

        let sentences = trimmed
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if sentences.isEmpty {
            return [trimmed]
        }

        return Array(sentences.prefix(2)).map { sentence in
            sentence.hasSuffix(".") ? sentence : sentence + "."
        }
    }

    private var overlayStateColor: Color {
        switch model.overlayState {
        case .recovery: .yellow
        case .answerReady: .blue
        case .speaking: .mint
        case .postAnswer: .green
        case .paused: .orange
        case .questionDetected: .purple
        case .listening, .idle: .gray
        }
    }
}

private enum OverlayLineStyle {
    case secondary
    case muted
    case accent

    var color: Color {
        switch self {
        case .secondary:
            return .white
        case .muted:
            return Color.white.opacity(0.78)
        case .accent:
            return Color(red: 0.76, green: 0.90, blue: 1.0)
        }
    }
}

struct SessionDetailView: View {
    @ObservedObject var model: AppModel
    let session: MeetingSessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.title3.weight(.semibold))
                    Text(session.configuration.meetingType.capitalized)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Refresh Summary") {
                    model.regenerateSummary(for: session.id)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                CompactMetric(title: "Transcript", value: "\(session.transcriptSegments.count)")
                CompactMetric(title: "Guidance", value: "\(session.guidanceHistory.count)")
                CompactMetric(title: "Docs", value: "\(session.documentIDs.count)")
            }

            if let summary = session.summary {
                DetailBlock(title: "Overview", text: summary.overview)

                DetailBlock(title: "Decision Summary", text: summary.decisionSummary)

                if !summary.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Action Items")
                            .font(.headline)
                        ForEach(summary.actionItems, id: \.self) { item in
                            BulletLine(text: item)
                        }
                    }
                }

                DetailBlock(title: "Follow-Up Draft", text: summary.followUpDraft)

                DetailBlock(title: "Outcome", text: summary.outcomeNote)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Follow-Up Notes")
                    .font(.headline)
                TextEditor(
                    text: Binding(
                        get: { session.followUpNotes },
                        set: { model.updateFollowUpNotes(for: session.id, notes: $0) }
                    )
                )
                .font(.body)
                .frame(minHeight: 110)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Guidance")
                    .font(.headline)
                if session.guidanceHistory.isEmpty {
                    EmptyStateCard(text: "No guidance captured in this session.")
                } else {
                    ForEach(session.guidanceHistory.prefix(4)) { snapshot in
                        DetailBlock(
                            title: timeLabel(snapshot.createdAt),
                            text: snapshot.content.nowSay + "\n\nAction: " + snapshot.content.next
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Transcript")
                    .font(.headline)
                if session.transcriptSegments.isEmpty {
                    EmptyStateCard(text: "No transcript captured yet.")
                } else {
                    ForEach(session.transcriptSegments.prefix(6)) { segment in
                        DetailBlock(title: segment.speaker, text: segment.text)
                    }
                }
            }
        }
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cuemate")
                .font(.headline)
            Text(model.overlayVisible ? "Overlay visible" : "Overlay hidden")
                .foregroundStyle(.secondary)

            Button(model.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                model.toggleOverlay()
            }

            Button(model.activeMeetingSession == nil ? "Start Session" : "End Session") {
                if model.activeMeetingSession == nil {
                    model.startMeetingSession()
                } else {
                    model.endMeetingSession()
                }
            }

            Button("Generate Response") {
                Task {
                    await model.generateConversationGuidance()
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        SettingsWorkspaceView(model: model)
            .padding(20)
    }
}

struct WorkspaceHeroCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.orange)
            Text(title)
                .font(.system(size: 30, weight: .semibold, design: .rounded))
            Text(subtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.95, blue: 0.90),
                            Color(red: 0.92, green: 0.96, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

struct SurfaceCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(nsColor: .underPageBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CompactMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct StatusDot: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
        }
    }
}

struct EmptyStateCard: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
    }
}

struct DetailBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(text)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct BulletLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
