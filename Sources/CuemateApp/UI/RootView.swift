import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @ObservedObject var model: AppModel
    @State private var openAIKeyInput = ""

    var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 270, idealWidth: 290, maxWidth: 320)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    switch model.selectedSection ?? .setup {
                    case .setup:
                        SetupWorkspaceView(model: model, openAIKeyInput: $openAIKeyInput)
                    case .live:
                        LiveWorkspaceView(model: model)
                    case .review:
                        ReviewWorkspaceView(model: model)
                    case .settings:
                        SettingsView(model: model)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    private var sidebar: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("cuemate")
                        .font(.title2.bold())

                    sidebarWorkspaceSection
                    sidebarLiveControlsSection
                    sidebarQuickActionsSection

                    Spacer(minLength: 12)
                }
                .padding(16)
            }
        }
    }

    private var sidebarWorkspaceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sidebarSectionTitle("Workspace")

            ForEach(AppModel.WorkspaceSection.allCases) { section in
                Button {
                    model.selectedSection = section
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: section))
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 22)
                        Text(section.title)
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(model.selectedSection == section ? Color.accentColor.opacity(0.18) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(model.selectedSection == section ? Color.accentColor.opacity(0.45) : Color.black.opacity(0.05), lineWidth: 1)
                )
            }
        }
    }

    private var sidebarLiveControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sidebarSectionTitle("Live Control")

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Show Overlay", isOn: overlayBinding)
                Toggle("Click Through Overlay", isOn: clickThroughBinding)
                Toggle("Pause Teleprompter", isOn: pauseBinding)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }

    private var sidebarQuickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sidebarSectionTitle("Quick Actions")

            quickActionButton(
                title: "Refresh Runtime Checks",
                subtitle: "Re-scan Ollama, whisper, and models",
                systemImage: "arrow.clockwise.circle.fill",
                tint: .blue
            ) {
                Task {
                    await model.refreshDependencyStatuses()
                }
            }

            quickActionButton(
                title: model.activeMeetingSession == nil ? "Start Session" : "End Session",
                subtitle: model.activeMeetingSession == nil ? "Create a meeting timeline before going live" : "Close the active meeting and save review data",
                systemImage: model.activeMeetingSession == nil ? "play.circle.fill" : "stop.circle.fill",
                tint: model.activeMeetingSession == nil ? .green : .red
            ) {
                if model.activeMeetingSession == nil {
                    model.startMeetingSession()
                } else {
                    model.endMeetingSession()
                }
            }

            quickActionButton(
                title: "Regenerate Suggestion",
                subtitle: "Create a fresh coaching answer",
                systemImage: "sparkles.rectangle.stack.fill",
                tint: .orange
            ) {
                model.regenerateSuggestion()
            }
        }
    }

    private func sidebarSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.8)
    }

    private func quickActionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                        .font(.system(size: 18, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.25), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func icon(for section: AppModel.WorkspaceSection) -> String {
        switch section {
        case .setup: "slider.horizontal.3"
        case .live: "waveform.and.mic"
        case .review: "clock.arrow.circlepath"
        case .settings: "gearshape"
        }
    }

    private var overlayBinding: Binding<Bool> {
        Binding(
            get: { model.overlayVisible },
            set: { _ in model.toggleOverlay() }
        )
    }

    private var clickThroughBinding: Binding<Bool> {
        Binding(
            get: { model.clickThroughEnabled },
            set: { model.setClickThrough($0) }
        )
    }

    private var pauseBinding: Binding<Bool> {
        Binding(
            get: { model.isPaused },
            set: { _ in model.togglePause() }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meeting Copilot Foundation")
                .font(.largeTitle.bold())

            Text("This shell keeps product setup inside the app. We can develop the native workflow now and let the finished app install runtime dependencies later with explicit user actions.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("The app now supports local-first provider selection: Apple Speech or whisper.cpp for STT, local heuristic or Ollama/OpenAI for response generation, plus an automatic live guidance loop.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SetupWorkspaceView: View {
    @ObservedObject var model: AppModel
    @Binding var openAIKeyInput: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            WorkspaceIntroCard(
                eyebrow: "Setup",
                title: "Install, test, then go live",
                subtitle: "Keep setup simple: make sure runtime is ready, test STT and overlay behavior, then save the meeting details you want before a real call."
            )
            FlowFormatCard(model: model)
            InstallerDashboardView(model: model)
            SetupTestLabView(model: model, openAIKeyInput: $openAIKeyInput)
            DisclosureGroup("Advanced meeting setup") {
                VStack(alignment: .leading, spacing: 24) {
                    ConfigurationView(model: model)
                    DocumentLibraryView(model: model)
                }
                .padding(.top, 16)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

struct SetupTestLabView: View {
    @ObservedObject var model: AppModel
    @Binding var openAIKeyInput: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(
                title: "Test Lab",
                subtitle: "Verify the core loop in one place: providers, microphone, transcript readiness, overlay position, and low-latency guidance generation."
            )

            ProviderSetupView(model: model, openAIKeyInput: $openAIKeyInput)
            SessionPrepCard(model: model)
            AudioPipelineView(model: model)
            ConversationEngineView(model: model)
            OverlayPreviewCard(model: model)
        }
    }
}

struct LiveWorkspaceView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            WorkspaceIntroCard(
                eyebrow: "Live",
                title: "Run one actual meeting flow",
                subtitle: "Name the meeting, keep the transcript moving, let guidance refresh with low latency, and keep the overlay where your eyes naturally return."
            )
            FlowFormatCard(model: model)
            SessionControlCard(model: model)
            AudioPipelineView(model: model)
            ConversationEngineView(model: model)
            OverlayPreviewCard(model: model)
            RetrievalWorkbenchView(model: model)
            SourceTraceView(model: model)
            SuggestionHistoryView(model: model)
            TeleprompterSyncView(model: model)
            PerformanceView(model: model)
            ActivityLogView(model: model)
        }
    }
}

struct ReviewWorkspaceView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            WorkspaceIntroCard(
                eyebrow: "Review",
                title: "Revisit past meetings and what the copilot suggested",
                subtitle: "Each meeting now stores transcript history and guidance snapshots locally so users can reopen a session instead of losing the context after the call."
            )
            MeetingHistoryView(model: model)
        }
    }
}

struct FlowFormatCard: View {
    @ObservedObject var model: AppModel

    private var latestQuestion: String {
        let text = model.latestTranscriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "No live question yet. Start mic capture or test STT first." : text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Two Flows",
                subtitle: "Keep the product centered around two simple modes instead of a debug-style surface."
            )

            HStack(alignment: .top, spacing: 16) {
                flowCard(
                    title: "Quick Start",
                    accent: Color.blue,
                    lines: [
                        "1. Install runtime and models",
                        "2. Test mic, STT, and overlay position",
                        "3. Start the meeting when the preview looks right"
                    ]
                )

                flowCard(
                    title: "Question / Answer / Action",
                    accent: Color.green,
                    lines: [
                        "Question: \(latestQuestion)",
                        "Answer: \(model.overlayContent.nowSay)",
                        "Action: \(model.overlayContent.next)"
                    ]
                )
            }
        }
    }

    private func flowCard(title: String, accent: Color, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(accent)
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.headline)
            }

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accent.opacity(0.25), lineWidth: 1)
        )
    }
}

struct AudioPipelineView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Audio Pipeline",
                subtitle: "This is the transcript-ready microphone boundary for the MVP. It requests mic permission, captures live frames, and exposes level/activity signals for the next STT task."
            )

            HStack(spacing: 12) {
                Button(model.audioCaptureState == .capturing ? "Stop Capture" : "Start Mic Capture") {
                    if model.audioCaptureState == .capturing {
                        model.stopMicrophoneCapture()
                    } else {
                        Task {
                            await model.requestMicrophoneAccessAndStart()
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Text("State: \(model.audioCaptureState.rawValue.capitalized)")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(model.manualInterruptionActive ? "Resume After Interruption" : "Trigger Manual Interruption") {
                    if model.manualInterruptionActive {
                        model.clearManualInterruption()
                    } else {
                        model.triggerManualInterruption()
                    }
                }
                .buttonStyle(.bordered)

                Text("Voice activity: \(model.voiceActivityState.rawValue.capitalized)")
                    .foregroundStyle(.secondary)

                Text("Interruption: \(model.interruptionState)")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Button(model.speechPermissionGranted ? "Speech Ready" : "Enable Transcription") {
                    Task {
                        await model.requestSpeechAccess()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(model.speechPermissionGranted || model.transcriptionState == .requestingPermission)

                Text("Transcription: \(model.transcriptionState.rawValue.capitalized)")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Permission: \(model.microphonePermissionGranted ? "Granted" : "Not granted")")
                    .foregroundStyle(.secondary)

                Text("\(model.transcriptionProvider.title): \(model.speechPermissionGranted ? "Ready" : "Not ready")")
                    .foregroundStyle(.secondary)

                Text("Frames captured: \(model.capturedFrameCount)")
                    .foregroundStyle(.secondary)

                Text(String(format: "Sample rate: %.0f Hz", model.audioSampleRate))
                    .foregroundStyle(.secondary)

                Text("Pause hotkey doubles as MVP interruption fallback")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Input level")
                        .font(.headline)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.gray.opacity(0.16))
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(model.audioLevel > 0.12 ? Color.green.opacity(0.75) : Color.blue.opacity(0.65))
                                .frame(width: max(8, proxy.size.width * model.audioLevel))
                        }
                    }
                    .frame(height: 18)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Latest Transcript")
                    .font(.headline)

                if model.latestTranscriptText.isEmpty {
                    Text("No transcript yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(model.latestTranscriptText)
                        .font(.callout)
                }

                if !model.transcriptSegments.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(model.transcriptSegments.prefix(4)) { segment in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(segment.speaker.capitalized)
                                        .font(.caption.weight(.semibold))
                                    Spacer()
                                    Text(segment.isFinal ? "Final" : "Live")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(segment.text)
                                    .font(.callout)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                        }
                    }
                }
            }
        }
    }
}

struct ProviderSetupView: View {
    @ObservedObject var model: AppModel
    @Binding var openAIKeyInput: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Providers",
                subtitle: "Choose how transcription and generation should work. Users can stay local, or save an OpenAI API key as a fallback when local runtime setup is not available."
            )

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Speaker Name")
                        .font(.headline)

                    TextField("Your name", text: $model.configuration.speakerName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 220, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Transcription")
                        .font(.headline)

                    Picker("Transcription", selection: $model.transcriptionProvider) {
                        ForEach(TranscriptionProvider.allCases) { provider in
                            Text(provider.title).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 220, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Generation")
                        .font(.headline)

                    Picker("Generation", selection: $model.generationProvider) {
                        ForEach(GenerationProvider.allCases) { provider in
                            Text(provider.title).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 220, alignment: .leading)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Toggle("Generate live responses automatically", isOn: $model.autoResponseEnabled)

                Text(model.autoResponseEnabled ? "Final transcript updates can trigger retrieval and guidance refresh automatically." : "Guidance stays manual until you press Generate Guidance.")
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("OpenAI API Key")
                    .font(.headline)

                HStack(spacing: 12) {
                    SecureField("sk-...", text: $openAIKeyInput)
                        .textFieldStyle(.roundedBorder)

                    Button("Save Key") {
                        model.saveOpenAIKey(openAIKeyInput)
                        openAIKeyInput = ""
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Clear Key") {
                        model.saveOpenAIKey("")
                        openAIKeyInput = ""
                    }
                    .buttonStyle(.bordered)
                }

                Text(model.openAIKeyPresent ? "OpenAI key is stored in Keychain." : "No OpenAI key stored.")
                    .foregroundStyle(.secondary)

                Text(model.providerStatusMessage)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            if model.transcriptionProvider == .whisperCpp {
                VStack(alignment: .leading, spacing: 10) {
                    Text("whisper.cpp Setup")
                        .font(.headline)

                    Text("The app can install `whisper-cli` through Homebrew and place the base GGML model in `~/Library/Application Support/cuemate/models/whisper/`. Use the Runtime Setup cards above, then press Enable Transcription again.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
        }
    }
}

struct SessionPrepCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Meeting Prep",
                subtitle: "Set the meeting name and your display name here so tests and live sessions feel like the real workflow instead of a generic demo shell."
            )

            HStack(spacing: 12) {
                TextField("Meeting title", text: $model.sessionDraftTitle)
                    .textFieldStyle(.roundedBorder)

                TextField("Your name", text: $model.configuration.speakerName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 16) {
                Label(model.sessionDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No title yet" : model.sessionDraftTitle, systemImage: "calendar")
                Label(model.configuration.speakerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Me" : model.configuration.speakerName, systemImage: "person.crop.circle")
            }
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct SessionControlCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Meeting Session",
                subtitle: "Start a meeting before the conversation begins so transcript updates and generated guidance are captured into a reviewable session history."
            )

            HStack(spacing: 12) {
                TextField("Meeting title", text: $model.sessionDraftTitle)
                    .textFieldStyle(.roundedBorder)

                TextField("Your name", text: $model.configuration.speakerName)
                    .textFieldStyle(.roundedBorder)

                Button(model.activeMeetingSession == nil ? "Start Meeting" : "Update Title") {
                    model.startMeetingSession()
                }
                .buttonStyle(.borderedProminent)

                if model.activeMeetingSession != nil {
                    Button("End Meeting") {
                        model.endMeetingSession()
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let activeSession = model.activeMeetingSession {
                HStack(spacing: 16) {
                    Label(activeSession.title, systemImage: "dot.radiowaves.left.and.right")
                    Text("\(activeSession.transcriptSegments.count) transcript items")
                    Text("\(activeSession.guidanceHistory.count) guidance items")
                }
                .foregroundStyle(.secondary)
            } else {
                Text("No active meeting session.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct RetrievalWorkbenchView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Context Retrieval",
                subtitle: "Search the imported chunk library now. This uses cached local hashed embeddings so ranking works even before Ollama embeddings are installed."
            )

            HStack(alignment: .center, spacing: 12) {
                TextField("Ask about pricing, rollout, interview prep, product features...", text: $model.retrievalQuery)
                    .textFieldStyle(.roundedBorder)

                Button("Search") {
                    model.runRetrieval()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.retrievalQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isSearching)
            }

            HStack(spacing: 16) {
                Text("Mode: \(model.retrievalModeLabel)")
                Text("Indexed chunks: \(model.indexedChunkCount)")
            }
            .foregroundStyle(.secondary)
            .font(.callout)

            VStack(spacing: 10) {
                if model.retrievalResults.isEmpty {
                    Text("No retrieval results yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(model.retrievalResults) { result in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(result.document.fileName)
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.2f", result.score))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }

                            Text(result.chunk.text)
                                .font(.callout)
                                .lineLimit(4)

                            if !result.matchedTerms.isEmpty {
                                Text("Matched: \(result.matchedTerms.joined(separator: ", "))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }
                }
            }
        }
    }
}

struct ConversationEngineView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Conversation Engine",
                subtitle: "Turn transcript history, retrieval context, and meeting settings into live speaking guidance. This can now run through the local heuristic engine, Ollama/Qwen, or OpenAI."
            )

            HStack(spacing: 12) {
                Button("Generate Guidance") {
                    Task {
                        await model.generateConversationGuidance()
                    }
                }
                .buttonStyle(.borderedProminent)

                Text("Mode: \(model.conversationModeLabel)")
                    .foregroundStyle(.secondary)

                Text("Live loop: \(model.liveResponseState)")
                    .foregroundStyle(.secondary)
            }

            if !model.streamingResponsePreview.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(model.isStreamingResponse ? "Streaming Draft" : "Latest Draft")
                            .font(.headline)
                        Spacer()
                        Text(model.isStreamingResponse ? "Low latency" : "Complete")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(model.isStreamingResponse ? .orange : .secondary)
                    }

                    Text(model.streamingResponsePreview)
                        .font(.callout)
                        .textSelection(.enabled)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Generation basis")
                    .font(.headline)

                Text(model.lastGenerationReason.isEmpty ? "No guidance generated yet." : model.lastGenerationReason)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

struct SourceTraceView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Source Trace",
                subtitle: "Show which uploaded material is most likely shaping the current guidance so the user can judge trust quickly during the meeting."
            )

            if let source = model.currentGuidanceSourceName {
                HStack {
                    Label(source, systemImage: "doc.text.magnifyingglass")
                    Spacer()
                    Text(model.conversationModeLabel)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            } else {
                emptyCard("No document source is attached to the current guidance yet.")
            }
        }
    }
}

struct SuggestionHistoryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Suggestion History",
                subtitle: "Keep a short in-meeting timeline of recent `NOW SAY` suggestions so the user can recover if they miss one in the moment."
            )

            if model.recentGuidanceSnapshots.isEmpty {
                emptyCard("Start a meeting session and generate guidance to build the recent suggestion timeline.")
            } else {
                VStack(spacing: 10) {
                    ForEach(model.recentGuidanceSnapshots) { snapshot in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(snapshot.provider)
                                    .font(.caption.weight(.semibold))
                                Spacer()
                                Text(historyTimeLabel(snapshot.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(snapshot.content.nowSay)
                                .font(.callout.weight(.semibold))

                            if let sourceDocumentName = snapshot.sourceDocumentName {
                                Text("Source: \(sourceDocumentName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }
                }
            }
        }
    }

    private func historyTimeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct TeleprompterSyncView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Teleprompter Sync",
                subtitle: "Track how much of the current `NOW SAY` guidance has been spoken. Read text fades into a completed lane while the remaining line stays foregrounded."
            )

            HStack(spacing: 16) {
                Text("State: \(model.teleprompterStateLabel)")
                    .foregroundStyle(.secondary)

                Text(String(format: "Progress: %.0f%%", model.teleprompterProgress * 100))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.gray.opacity(0.16))
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.orange.opacity(0.72))
                        .frame(width: max(8, proxy.size.width * model.teleprompterProgress))
                }
            }
            .frame(height: 20)

            VStack(alignment: .leading, spacing: 8) {
                if !model.teleprompterReadText.isEmpty {
                    Text(model.teleprompterReadText)
                        .foregroundStyle(.secondary)
                        .opacity(0.45)
                }

                Text(model.teleprompterRemainingText.isEmpty ? model.overlayContent.nowSay : model.teleprompterRemainingText)
                    .font(.title3.weight(.semibold))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

struct PerformanceView: View {
    @ObservedObject var model: AppModel

    private let rows: [(String, String)] = [
        ("transcription", "Transcription"),
        ("retrieval", "Retrieval"),
        ("generation", "Generation"),
        ("ui_refresh", "UI Refresh")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Performance Budgets",
                subtitle: "Track the key PRD latency targets from inside the app while we build. Values update as you use retrieval, transcription, generation, and teleprompter sync."
            )

            VStack(spacing: 10) {
                ForEach(rows, id: \.0) { key, title in
                    let sample = model.performanceSummary.latest(named: key)
                    HStack {
                        Text(title)
                        Spacer()
                        if let sample {
                            Text(String(format: "%.1fms / %.0fms", sample.durationMs, sample.budgetMs))
                                .font(.callout.monospaced())
                                .foregroundStyle(sample.withinBudget ? Color.green : Color.red)
                        } else {
                            Text("No sample yet")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

struct DocumentLibraryView: View {
    @ObservedObject var model: AppModel
    @State private var importing = false

    private var allowedTypes: [UTType] {
        var base: [UTType] = [.pdf, .plainText, .text, .utf8PlainText]
        if let markdown = UTType(filenameExtension: "md") {
            base.append(markdown)
        }
        return base
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Document Library",
                subtitle: "Import PDF, TXT, and Markdown files into the local knowledge store. Files are copied into app support storage and chunked for later retrieval."
            )

            HStack(spacing: 12) {
                Button("Import Documents") {
                    importing = true
                }
                .buttonStyle(.borderedProminent)

                if model.lastImportedChunkCount > 0 {
                    Text("Last import: \(model.lastImportedChunkCount) chunks")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 10) {
                if model.importedDocuments.isEmpty {
                    Text("No documents imported yet.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(model.importedDocuments) { document in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(document.fileName)
                                    .font(.headline)
                                Text("\(document.fileType.uppercased()) • \(document.chunkCount) chunks • \(document.characterCount) chars")
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                                Text(document.sourcePath)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    let granted = url.startAccessingSecurityScopedResource()
                    defer {
                        if granted {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    model.importDocument(from: url)
                }
            case .failure(let error):
                model.appendLog("File import cancelled or failed: \(error.localizedDescription)")
            }
        }
    }
}

struct InstallerDashboardView: View {
    @ObservedObject var model: AppModel

    private var actionableItems: [InstallerItemViewModel] {
        model.dependencyItems.filter { item in
            switch item.status {
            case .missing, .failed, .installing, .pending:
                return true
            case .ready, .optional:
                return false
            }
        }
    }

    private var readyItems: [InstallerItemViewModel] {
        model.dependencyItems.filter { $0.status == .ready || $0.status == .optional }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Local Runtime Setup",
                subtitle: "These dependencies are checked from inside the app so the product can own setup instead of requiring a manual preinstall flow."
            )

            if actionableItems.isEmpty {
                DisclosureGroup("All runtime components look ready", isExpanded: $model.runtimeSetupExpanded) {
                    LazyVStack(spacing: 12) {
                        ForEach(readyItems) { item in
                            dependencyCard(item)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(actionableItems) { item in
                        dependencyCard(item)
                    }
                }

                if !readyItems.isEmpty {
                    DisclosureGroup("Installed components", isExpanded: $model.runtimeSetupExpanded) {
                        LazyVStack(spacing: 12) {
                            ForEach(readyItems) { item in
                                dependencyCard(item)
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func dependencyCard(_ item: InstallerItemViewModel) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.descriptor.title)
                    .font(.headline)

                Text(item.descriptor.summary)
                    .foregroundStyle(.secondary)

                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if item.status == .installing {
                    ProgressView(value: item.progress ?? 0)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 220)
                        .padding(.top, 6)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                StatusBadge(status: item.status)

                Button(buttonTitle(for: item)) {
                    Task {
                        await model.performInstall(for: item.id)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(item.status == .installing || item.status == .ready)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func buttonTitle(for item: InstallerItemViewModel) -> String {
        switch item.status {
        case .ready:
            return "Installed"
        case .failed:
            return "Retry"
        case .installing:
            return "Installing…"
        case .missing, .optional, .pending:
            return item.descriptor.installActionTitle
        }
    }
}

struct ConfigurationView: View {
    @ObservedObject var model: AppModel

    let meetingTypes = ["sales", "interview", "demo", "internal"]
    let userLevels = ["beginner", "expert"]
    let tones = ["friendly", "confident", "technical"]
    let lengths = ["short", "medium", "long"]
    let creativityLevels = ["safe", "balanced", "bold"]
    let modes = ["passive", "active"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Meeting Configuration",
                subtitle: "These fields mirror the PRD so later pipeline work can plug into stable local settings."
            )

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                GridRow {
                    picker("Meeting Type", selection: $model.configuration.meetingType, options: meetingTypes)
                    picker("User Level", selection: $model.configuration.userLevel, options: userLevels)
                }
                GridRow {
                    picker("Tone", selection: $model.configuration.tone, options: tones)
                    picker("Length", selection: $model.configuration.length, options: lengths)
                }
                GridRow {
                    picker("Creativity", selection: $model.configuration.creativity, options: creativityLevels)
                    picker("AI Mode", selection: $model.configuration.aiMode, options: modes)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }

    private func picker(_ title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option.capitalized).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct OverlayPreviewCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Overlay Preview",
                subtitle: "Preview the final coaching format and place it where your eyes naturally return during a meeting."
            )

            OverlayPanelView(model: model)
                .frame(maxWidth: 460)

            VStack(alignment: .leading, spacing: 12) {
                Text("Overlay position")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Anchor")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Anchor", selection: $model.overlayAnchor) {
                        ForEach(OverlayAnchor.allCases) { anchor in
                            Text(anchor.title).tag(anchor)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Horizontal Offset")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $model.overlayHorizontalInset, in: -220...220, step: 4)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Vertical Offset")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $model.overlayVerticalInset, in: 0...220, step: 4)
                    }
                }

                Button("Apply Overlay Position") {
                    model.pinOverlayNearCamera()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            HStack(spacing: 12) {
                Button("Regenerate") {
                    model.regenerateSuggestion()
                }

                Button("Shorten") {
                    model.shortenSuggestion()
                }

                Button("Expand") {
                    model.expandSuggestion()
                }

                Button("More Confident") {
                    model.markMoreConfident()
                }

            }

            Button(model.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                model.toggleOverlay()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct HotkeyReferenceView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(
                title: "Global Hotkeys",
                subtitle: "These shortcuts follow the PRD so the live workflow stays usable even when the main window is not frontmost."
            )

            VStack(spacing: 10) {
                ForEach(ConversationAction.allCases) { action in
                    HStack {
                        Text(action.title)
                        Spacer()
                        Text(action.shortcutLabel)
                            .foregroundStyle(.secondary)
                            .font(.callout.monospaced())
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

struct OverlayPanelView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(model.isPaused ? "PAUSED" : "LIVE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(model.isPaused ? Color.orange.opacity(0.95) : Color.green.opacity(0.95))

                Spacer()

                Text(model.confidenceMode.capitalized)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.72))
            }

            overlayLine(title: "QUESTION", body: questionLine, prominent: false)
            overlayLine(title: "ANSWER", body: model.overlayContent.nowSay, prominent: true)
            overlayLine(title: "ACTION", body: model.overlayContent.next, prominent: false)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.12, blue: 0.17).opacity(0.92),
                            Color(red: 0.17, green: 0.21, blue: 0.30).opacity(0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 10)
        .padding(.vertical, 4)
    }

    private func overlayLine(title: String, body: String, prominent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.70))

            Text(body)
                .font(prominent ? .title3.weight(.semibold) : .callout)
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var questionLine: String {
        let text = model.latestTranscriptText.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? "Waiting for the meeting question" : text
    }
}

struct ActivityLogView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: "Activity Log",
                subtitle: "A simple local event stream for setup and interaction feedback."
            )

            VStack(alignment: .leading, spacing: 8) {
                ForEach(model.activityLog.prefix(8), id: \.self) { entry in
                    Text(entry)
                        .font(.callout.monospaced())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if model.activityLog.isEmpty {
                    Text("No events yet.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
    }
}

struct MeetingHistoryView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(
                    title: "Saved Meetings",
                    subtitle: "Recent sessions stay local on this machine."
                )

                if model.meetingSessions.isEmpty {
                    emptyCard("No meetings saved yet.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(model.meetingSessions) { session in
                            Button {
                                model.selectSession(session.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(session.title)
                                            .font(.headline)
                                        Spacer()
                                        Text(session.isActive ? "Live" : "Saved")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(session.isActive ? Color.green : .secondary)
                                    }

                                    Text(sessionDateLabel(session))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("\(session.transcriptSegments.count) transcript items • \(session.guidanceHistory.count) suggestions")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(model.selectedSessionID == session.id ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .frame(maxWidth: 320, alignment: .leading)

            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(
                    title: "Session Detail",
                    subtitle: "Summary, action items, transcript, and guidance history for the selected meeting."
                )

                if let session = model.selectedReviewSession {
                    SessionDetailView(model: model, session: session)
                } else {
                    emptyCard("Select a meeting to review it.")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func sessionDateLabel(_ session: MeetingSessionRecord) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if let endedAt = session.endedAt {
            return "\(formatter.string(from: session.startedAt)) to \(formatter.string(from: endedAt))"
        }

        return "Started \(formatter.string(from: session.startedAt))"
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
                        .font(.title3.bold())
                    Text(session.configuration.meetingType.capitalized + " • " + session.configuration.tone.capitalized + " • " + session.configuration.length.capitalized)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(session.isActive ? "In progress" : "Completed")
                    .foregroundStyle(session.isActive ? Color.green : .secondary)
            }

            MetricStripView(items: [
                ("Transcript", "\(session.transcriptSegments.count)"),
                ("Suggestions", "\(session.guidanceHistory.count)"),
                ("Docs", "\(session.documentIDs.count)")
            ])

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Post-Meeting Summary")
                        .font(.headline)
                    Spacer()
                    Button("Refresh Summary") {
                        model.regenerateSummary(for: session.id)
                    }
                    .buttonStyle(.bordered)
                }

                if let summary = session.summary {
                    VStack(alignment: .leading, spacing: 12) {
                        summaryCard(
                            title: "Overview",
                            body: summary.overview
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Topics")
                                .font(.subheadline.weight(.semibold))
                            if summary.keyTopics.isEmpty {
                                Text("No key topics extracted yet.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(summary.keyTopics, id: \.self) { topic in
                                    bulletRow(topic)
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Action Items")
                                .font(.subheadline.weight(.semibold))
                            if summary.actionItems.isEmpty {
                                Text("No action items generated yet.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(summary.actionItems, id: \.self) { item in
                                    bulletRow(item)
                                }
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )

                        summaryCard(
                            title: "Outcome",
                            body: summary.outcomeNote
                        )
                    }
                } else {
                    emptyCard("Finish a meeting or refresh the summary to generate a recap.")
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Follow-Up Notes")
                    .font(.headline)

                TextEditor(
                    text: Binding(
                        get: { session.followUpNotes },
                        set: { model.updateFollowUpNotes(for: session.id, notes: $0) }
                    )
                )
                .font(.body)
                .frame(minHeight: 120)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Guidance Timeline")
                    .font(.headline)

                if session.guidanceHistory.isEmpty {
                    emptyCard("No guidance was captured for this meeting yet.")
                } else {
                    ForEach(session.guidanceHistory.prefix(6)) { snapshot in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(snapshot.provider)
                                    .font(.caption.weight(.semibold))
                                Spacer()
                                Text(timeLabel(snapshot.createdAt))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(snapshot.content.nowSay)
                                .font(.callout.weight(.semibold))
                            Text(snapshot.content.why)
                                .foregroundStyle(.secondary)
                            if let sourceDocumentName = snapshot.sourceDocumentName {
                                Text("Source: \(sourceDocumentName)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Transcript")
                    .font(.headline)

                if session.transcriptSegments.isEmpty {
                    emptyCard("No transcript captured for this meeting yet.")
                } else {
                    ForEach(session.transcriptSegments.prefix(8)) { segment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(segment.speaker.capitalized)
                                    .font(.caption.weight(.semibold))
                                Spacer()
                                Text(segment.isFinal ? "Final" : "Live")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(segment.text)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
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

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func summaryCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(body)
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

struct WorkspaceIntroCard: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.orange)

            Text(title)
                .font(.title2.bold())

            Text(subtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.94, blue: 0.89),
                            Color(red: 0.91, green: 0.95, blue: 0.97)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }
}

struct MetricStripView: View {
    let items: [(String, String)]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.1)
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("cuemate")
                .font(.headline)

            Text(model.overlayVisible ? "Overlay is live" : "Overlay is hidden")
                .foregroundStyle(.secondary)

            Button(model.overlayVisible ? "Hide Overlay" : "Show Overlay") {
                model.toggleOverlay()
            }

            Button("Refresh Runtime Checks") {
                Task {
                    await model.refreshDependencyStatuses()
                }
            }

            Divider()

            Text("Models ready: \(model.dependencyItems.filter { $0.status == .ready }.count)/\(model.dependencyItems.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }
}

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeader(
                title: "Settings",
                subtitle: "The app support folder is created immediately so logs, models, documents, and config can all move into one local-first location."
            )

            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Text(model.appPaths.baseDirectory.path)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)

                    Text("Subdirectories: models, documents, embeddings, logs, config, sessions")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(20)
    }
}

struct StatusBadge: View {
    let status: DependencyStatus

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background, in: Capsule())
    }

    private var label: String {
        switch status {
        case .ready: "Ready"
        case .missing: "Missing"
        case .optional: "Manual"
        case .pending: "Checking"
        case .installing: "Installing"
        case .failed: "Failed"
        }
    }

    private var background: Color {
        switch status {
        case .ready: Color.green.opacity(0.18)
        case .missing: Color.orange.opacity(0.18)
        case .optional: Color.blue.opacity(0.18)
        case .pending: Color.gray.opacity(0.18)
        case .installing: Color.yellow.opacity(0.22)
        case .failed: Color.red.opacity(0.18)
        }
    }
}

@ViewBuilder
private func sectionHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .font(.title2.bold())

        Text(subtitle)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

@ViewBuilder
private func emptyCard(_ message: String) -> some View {
    Text(message)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
}
