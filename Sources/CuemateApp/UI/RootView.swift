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
            VStack(alignment: .leading, spacing: 3) {
                Text("Cuemate")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Clean live help for meetings, demos, and client calls.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if model.offlineModeEnabled {
                HStack(spacing: 5) {
                    Image(systemName: "wifi.slash")
                        .font(.caption.weight(.semibold))
                    Text("Offline")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule(style: .continuous).fill(Color.orange))
            }

            if !model.backgroundTaskLabel.isEmpty {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.65)
                        .frame(width: 14, height: 14)
                    Text(model.backgroundTaskLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }

            HStack(spacing: 8) {
                navPill(for: .live, icon: "play.circle.fill")
                navPill(for: .review, icon: "clock.arrow.circlepath")
                navPill(for: .setup, icon: "gearshape.fill")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func navPill(for section: AppModel.WorkspaceSection, icon: String) -> some View {
        let isActive = model.selectedSection == section
        return Button {
            model.selectedSection = section
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(isActive ? Color.accentColor.opacity(0.35) : Color.black.opacity(0.05), lineWidth: 1)
            )
            .foregroundStyle(isActive ? Color.accentColor : Color.primary)
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
                    if model.showAutoStartSuggestion {
                        autoStartSuggestionCard
                    }
                    if let playbook = model.activePlaybook {
                        activePlaybookBanner(playbook)
                    }
                    sessionCard
                    meetingContextCard
                    meetingGoalsCard
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
                    diagnosticsCard
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

                if model.activeMeetingSession != nil {
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Get Response",
                            systemImage: "sparkles",
                            tint: .blue
                        ) {
                            Task {
                                await model.requestGuidanceFromCurrentTranscript()
                            }
                        }

                        ActionButton(
                            title: model.isPaused ? "Resume Scroll" : "Pause Scroll",
                            systemImage: model.isPaused ? "play.fill" : "pause.fill",
                            tint: .gray
                        ) {
                            model.togglePause()
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

    private func activePlaybookBanner(_ playbook: MeetingPlaybook) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "book.closed.fill")
                .font(.caption)
                .foregroundStyle(.purple)
            Text("Playbook active:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(playbook.name)
                .font(.caption.weight(.semibold))
            Spacer()
            Button("Change") { model.selectedSection = .settings }
                .font(.caption)
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.purple.opacity(0.07))
        )
    }

    private var autoStartSuggestionCard: some View {
        SurfaceCard {
            HStack(spacing: 14) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Meeting Detected")
                        .font(.subheadline.weight(.semibold))
                    Text("Cuemate is picking up a conversation. Start a session to get live guidance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button("Start Session") {
                        model.startMeetingSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Dismiss") {
                        model.dismissAutoStartSuggestion()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var meetingGoalsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Goals")
                        .font(.title3.weight(.semibold))
                    Text("Optional. Helps Cuemate focus live guidance on what you want to achieve.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Meeting goal (e.g. agree on pilot scope)", text: $model.configuration.meetingGoal)
                    .textFieldStyle(.roundedBorder)

                TextField("Target outcome (e.g. get a signed NDA)", text: $model.configuration.targetOutcome)
                    .textFieldStyle(.roundedBorder)

                TextField("Must-cover points (comma-separated)", text: $model.configuration.mustCoverPoints)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var meetingContextCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Meeting Context")
                            .font(.title3.weight(.semibold))
                        Text("Optional. Helps Cuemate tailor guidance and briefs to the specific person and relationship.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Flow")
                        .font(.subheadline.weight(.semibold))

                    HStack(spacing: 10) {
                        meetingFlowButton(title: "Remote", active: model.effectiveMeetingCaptureMode == .remote) {
                            model.setMeetingCaptureMode(.remote)
                        }

                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Text("In-Person")
                                Text("Later")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(Color.orange.opacity(0.16))
                                    )
                            }
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
                            )
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(true)
                    }

                    Text(model.meetingCaptureModeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Participant name", text: $model.configuration.participantName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Company", text: $model.configuration.participantCompany)
                        .textFieldStyle(.roundedBorder)
                }

                Picker("Relationship", selection: $model.configuration.relationshipStage) {
                    Text("New contact").tag("new")
                    Text("Ongoing").tag("ongoing")
                    Text("Strategic").tag("strategic")
                }
                .pickerStyle(.segmented)

                Picker("Language", selection: $model.configuration.meetingLanguage) {
                    ForEach(MeetingLanguage.allCases) { lang in
                        Text(lang.title).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: model.configuration.meetingLanguage) { _, _ in
                    model.applyMeetingLanguageToTranscriptionServices()
                }

                TextField("Prior context note (optional)", text: $model.configuration.priorContextNote)
                    .textFieldStyle(.roundedBorder)

                Divider()

                if let event = model.importedCalendarEvent {
                    calendarEventRow(event)
                } else {
                    Button("Import Calendar Event (.ics)") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.init(filenameExtension: "ics")!]
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            model.importCalendarEvent(from: url)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                if !model.configuration.participantName.isEmpty || !model.configuration.participantCompany.isEmpty {
                    Text(model.participantContextSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func meetingFlowButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(active ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(active ? Color.accentColor.opacity(0.35) : Color.black.opacity(0.06), lineWidth: 1)
                )
                .foregroundStyle(active ? Color.accentColor : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private func calendarEventRow(_ event: CalendarEventRecord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.blue)
                    .font(.caption)
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title.isEmpty ? "Imported Event" : event.title)
                        .font(.caption.weight(.semibold))
                    if let start = event.startDate {
                        Text(start, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Button("Clear") { model.clearCalendarEvent() }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }

            if !event.attendeeNames.isEmpty {
                Text("Attendees: \(event.attendeeNames.prefix(5).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if !event.agenda.isEmpty {
                Text(event.agenda.prefix(120).description + (event.agenda.count > 120 ? "…" : ""))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.blue.opacity(0.06))
        )
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
                            await model.requestGuidanceFromCurrentTranscript()
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
                .fontDesign(.rounded)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(active ? Color.accentColor : Color.primary.opacity(0.7))
                .background(
                    Capsule(style: .continuous)
                        .fill(active ? Color.accentColor.opacity(0.14) : Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(active ? Color.accentColor.opacity(0.35) : Color.black.opacity(0.05), lineWidth: 1)
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
                if model.screenContextEnabled {
                    CompactMetric(
                        title: "Screen",
                        value: model.screenContextText.isEmpty ? "No capture yet" : "\(model.screenContextText.count) chars"
                    )
                }
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

    private var diagnosticsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Session Diagnostics")
                    .font(.title3.weight(.semibold))

                ForEach(model.sessionDiagnosticsItems, id: \.self) { item in
                    BulletLine(text: item)
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

            if !model.pendingFollowUpSessions.isEmpty {
                needsAttentionCard
            }

            SurfaceCard {
                if model.historyState.sessions.isEmpty {
                    EmptyStateCard(text: "No saved sessions yet.")
                } else {
                    SessionHistoryView(
                        sessions: model.historyState.sessions,
                        documents: model.historyState.documents,
                        selectedID: $model.selectedSessionID
                    )
                    .frame(minHeight: 620)
                }
            }
        }
    }

    private var needsAttentionCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                        Text("Needs Attention")
                            .font(.title3.weight(.semibold))
                    }
                    Spacer()
                    Text("\(model.pendingFollowUpSessions.count) pending")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                ForEach(model.pendingFollowUpSessions) { session in
                    pendingFollowUpRow(session)
                }
            }
        }
    }

    private func pendingFollowUpRow(_ session: MeetingSessionRecord) -> some View {
        let itemCount = session.summary?.actionItems.count ?? 0
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let endedAt = session.endedAt {
                        Text(RelativeDateTimeFormatter().localizedString(for: endedAt, relativeTo: Date()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("·")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                    Text("\(itemCount) action item\(itemCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button("Open") {
                    model.selectSession(session.id)
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderless)
                .foregroundStyle(Color.accentColor)

                Button("Mark Done") {
                    model.markFollowUpDone(for: session.id)
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.borderless)
                .foregroundStyle(Color.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.orange.opacity(0.15), lineWidth: 1)
        )
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
                    audioRoutingCard
                    providerCard
                    offlineModeCard
                    screenContextCard
                    playbookCard
                    privacyCard
                    memoryControlsCard
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

                Picker("Transcript interpretation", selection: $model.transcriptInterpretationMode) {
                    ForEach(TranscriptInterpretationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(model.transcriptInterpretationSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Response", selection: $model.generationProvider) {
                    ForEach(GenerationProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Auto-submit from final transcript", isOn: $model.autoResponseEnabled)

                if model.transcriptInterpretationMode == .sharedRoom {
                    Text("Shared-room mode works better with manual Get Response. Auto-submit can fire too early on mixed room audio.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Output mode", selection: $model.openAIOutputMode) {
                    ForEach(OpenAIOutputMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(true)

                Picker("OpenAI model profile", selection: $model.openAIModelProfile) {
                    ForEach(OpenAIModelProfile.allCases) { profile in
                        Text(profile.title).tag(profile)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected OpenAI model: \(model.selectedOpenAIModel)")
                        .font(.caption.weight(.semibold))
                    Text(model.openAIProfileSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Cuemate only asks Keychain for the API key when it actually needs it, so the app should stop prompting on launch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                SecureField("OpenAI API key (optional)", text: $openAIKeyInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save OpenAI Key") {
                        guard openAIKeyInput != "Saved in Keychain" else { return }
                        model.saveOpenAIKey(openAIKeyInput)
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

    private var audioRoutingCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Audio Routing Check")
                            .font(.title3.weight(.semibold))
                        Text("Verify that Cuemate can see BlackHole, the current system output, and your earphone or headset path.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 10) {
                    Button("Run Audio Check") {
                        model.runAudioRoutingCheck()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Play Test Beep") {
                        model.playSystemAudioTestBeep()
                    }
                    .buttonStyle(.bordered)
                }

                Text(model.audioRoutingSummary)
                    .font(.subheadline.weight(.semibold))

                ForEach(model.audioRoutingItems, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "waveform.path")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("If macOS output is set to Multi-Output Device, the test beep should go to both your speakers or earphones and the BlackHole path.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var offlineModeCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Offline Mode")
                            .font(.title3.weight(.semibold))
                        Text("Forces all generation to the local heuristic engine regardless of provider selection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $model.offlineModeEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    offlineModeCapabilityRow(icon: "checkmark.circle.fill", color: .green,
                        label: "Live guidance", note: "Always available — local heuristic")
                    offlineModeCapabilityRow(icon: "checkmark.circle.fill", color: .green,
                        label: "Transcription", note: "Apple Speech or whisper.cpp")
                    offlineModeCapabilityRow(icon: "checkmark.circle.fill", color: .green,
                        label: "Session history & memory", note: "Fully local")
                    offlineModeCapabilityRow(
                        icon: model.offlineModeEnabled ? "xmark.circle.fill" : "checkmark.circle.fill",
                        color: model.offlineModeEnabled ? .secondary : .green,
                        label: "AI brief generation",
                        note: model.offlineModeEnabled ? "Paused in offline mode" : "Available with OpenAI or Ollama"
                    )
                }

                if model.offlineModeEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Offline mode is on. Brief generation uses heuristic templates only. Turn it off to re-enable cloud providers.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func offlineModeCapabilityRow(icon: String, color: Color, label: String, note: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption.weight(.medium))
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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

                HStack {
                    Text("Meeting flow")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(model.effectiveMeetingCaptureMode.title)
                        .font(.caption.weight(.semibold))
                }

                Text("Remote mode is active. In-person capture is intentionally disabled until room capture is ready.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Meeting type", selection: $model.configuration.meetingType) {
                    ForEach(MeetingMode.allCases) { mode in
                        Text(mode.title).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.menu)

                Picker("Meeting language", selection: $model.configuration.meetingLanguage) {
                    ForEach(MeetingLanguage.allCases) { lang in
                        Text(lang.title).tag(lang.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: model.configuration.meetingLanguage) { _, _ in
                    model.applyMeetingLanguageToTranscriptionServices()
                }

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

                if let suggested = model.suggestedAnswerStyle, suggested != model.confidenceMode {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Past sessions suggest \(suggested.capitalized). ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Apply") {
                            model.confidenceMode = suggested
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.blue)
                    }
                }

                Toggle("Click through overlay", isOn: Binding(
                    get: { model.clickThroughEnabled },
                    set: { model.setClickThrough($0) }
                ))
            }
        }
    }

    private var screenContextCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Screen Context")
                            .font(.title3.weight(.semibold))
                        Text("Captures visible text from your display via on-device OCR and passes it to guidance as slide or shared-content context.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $model.screenContextEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                if !model.screenPermissionGranted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Screen Recording permission is required.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Grant Access") {
                            model.requestScreenPermission()
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                } else if model.screenContextEnabled {
                    HStack(spacing: 10) {
                        Button("Refresh Now") {
                            Task { await model.refreshScreenContext() }
                        }
                        .buttonStyle(.bordered)

                        if let capturedAt = model.screenContextCapturedAt {
                            Text("Last capture \(RelativeDateTimeFormatter().localizedString(for: capturedAt, relativeTo: Date()))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !model.screenContextText.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CAPTURED TEXT PREVIEW")
                                .font(.caption2.weight(.bold))
                                .tracking(0.8)
                                .foregroundStyle(.tertiary)
                            Text(String(model.screenContextText.prefix(300)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineLimit(6)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Text is extracted on-device and never stored to disk or sent independently of your chosen AI provider.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Enable to let Cuemate read visible slide text and shared-screen content as additional context during live guidance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

    private var playbookCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Team Playbooks")
                            .font(.title3.weight(.semibold))
                        Text("Activate a playbook to inject team-specific coaching cues, focus areas, and context into every session.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if model.activePlaybook != nil {
                        StatusDot(title: "Active", color: .green)
                    }
                }

                if let active = model.activePlaybook {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text(active.name)
                            .font(.caption.weight(.semibold))
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(active.meetingType.replacingOccurrences(of: "-", with: " ").capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Deactivate") { model.activatePlaybook(nil) }
                            .font(.caption)
                            .buttonStyle(.borderless)
                            .foregroundStyle(.secondary)
                    }

                    if !active.teamContext.isEmpty {
                        Text(active.teamContext.prefix(200).description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider()
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.playbooks) { playbook in
                        playbookRow(playbook)
                    }
                }

                HStack(spacing: 10) {
                    Button("New Playbook") {
                        model.createPlaybook(
                            name: "My \(model.configuration.meetingType.replacingOccurrences(of: "-", with: " ").capitalized) Playbook",
                            meetingType: model.configuration.meetingType
                        )
                    }
                    .buttonStyle(.bordered)

                    Button("Import .json") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.json]
                        panel.allowsMultipleSelection = false
                        if panel.runModal() == .OK, let url = panel.url {
                            model.importPlaybook(from: url)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func playbookRow(_ playbook: MeetingPlaybook) -> some View {
        let isActive = model.activePlaybookID == playbook.id
        return HStack(spacing: 10) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isActive ? Color.green : Color.secondary)
                .font(.caption)

            VStack(alignment: .leading, spacing: 1) {
                Text(playbook.name)
                    .font(.caption.weight(isActive ? .semibold : .regular))
                    .lineLimit(1)
                Text(playbook.meetingType.replacingOccurrences(of: "-", with: " ").capitalized
                     + (playbook.isBuiltIn ? " · Built-in" : ""))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button(isActive ? "Active" : "Use") {
                model.activatePlaybook(isActive ? nil : playbook.id)
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .foregroundStyle(isActive ? Color.secondary : Color.accentColor)

            if !playbook.isBuiltIn {
                Button(action: { model.exportPlaybook(playbook) }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)

                Button(action: { model.deletePlaybook(playbook.id) }) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red.opacity(0.7))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isActive ? Color.green.opacity(0.06) : Color(nsColor: .controlBackgroundColor))
        )
    }

    private var memoryControlsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory Controls")
                            .font(.title3.weight(.semibold))
                        Text("Control which sessions contribute to live guidance and pre-meeting context.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $model.memoryEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                if model.memoryEnabled {
                    let sources = model.memorySources
                    if sources.isEmpty {
                        Text("No sessions are contributing to memory yet. Complete a session with the current meeting configuration to build context.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("CONTRIBUTING SESSIONS")
                                    .font(.caption2.weight(.bold))
                                    .tracking(0.8)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                if !model.excludedFromMemoryIDs.isEmpty {
                                    Button("Clear exclusions") {
                                        model.clearMemoryExclusions()
                                    }
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                                    .buttonStyle(.plain)
                                }
                            }

                            ForEach(sources) { session in
                                memorySourceRow(session)
                            }
                        }

                        let excluded = model.excludedFromMemoryIDs.count
                        if excluded > 0 {
                            Text("\(excluded) session\(excluded == 1 ? "" : "s") excluded from memory.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("CURRENT MEMORY NOTE")
                            .font(.caption2.weight(.bold))
                            .tracking(0.8)
                            .foregroundStyle(.tertiary)
                        ForEach(model.recurringMemoryItems, id: \.self) { line in
                            HStack(alignment: .top, spacing: 6) {
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(line)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else {
                    Text("Memory is off. Live guidance will not include past session context for this meeting type or participant.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func memorySourceRow(_ session: MeetingSessionRecord) -> some View {
        let excluded = model.excludedFromMemoryIDs.contains(session.id)
        return HStack(spacing: 10) {
            Image(systemName: excluded ? "circle.slash" : "checkmark.circle.fill")
                .foregroundStyle(excluded ? Color.secondary : Color.green)
                .font(.caption)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                if let date = session.endedAt {
                    Text(RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if let outcome = session.sessionOutcome {
                Text(outcome.title)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background((excluded ? Color.gray : outcomeAccentColor(outcome)).opacity(0.75))
                    .cornerRadius(3)
            }

            Button(excluded ? "Include" : "Exclude") {
                model.toggleMemoryExclusion(for: session.id)
            }
            .font(.caption)
            .buttonStyle(.borderless)
            .foregroundStyle(excluded ? Color.accentColor : Color.secondary)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(excluded ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : Color(nsColor: .controlBackgroundColor))
        )
        .opacity(excluded ? 0.6 : 1.0)
    }

    private func outcomeAccentColor(_ outcome: SessionOutcome) -> Color {
        switch outcome {
        case .pilot: .green
        case .followUp: .blue
        case .blocked: .red
        case .internalAction: .orange
        case .openRisk: .yellow
        case .unclear: .gray
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

                VStack(alignment: .leading, spacing: 6) {
                    Text("Opacity")
                        .font(.caption.weight(.semibold))
                    Slider(value: $model.overlayOpacity, in: 0.45...1.0, step: 0.01)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Spacer()
                overlayControlButton(
                    title: "Generate",
                    systemImage: "sparkles"
                ) {
                    Task {
                        await model.requestGuidanceFromCurrentTranscript()
                    }
                }
                overlayControlButton(
                    title: model.isPaused ? "Resume" : "Pause",
                    systemImage: model.isPaused ? "play.fill" : "pause.fill"
                ) {
                    model.togglePause()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Heard")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(latestHeardText)
                    .font(.callout)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(3)
            }

            ScrollView {
                Text(primaryAnswerText)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 72, maxHeight: 180)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 0.09, green: 0.11, blue: 0.14).opacity(model.overlayOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
    }

    private var primaryAnswerText: String {
        let trimmed = model.liveResponseText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Waiting for answer." : trimmed
    }

    private var latestHeardText: String {
        let trimmed = model.latestQuestionText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Waiting for transcript." : trimmed
    }

    private func overlayControlButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
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
                    await model.requestGuidanceFromCurrentTranscript()
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
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(Color.accentColor.opacity(0.7))
            Text(title)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(nsColor: .underPageBackgroundColor),
                            Color(nsColor: .windowBackgroundColor)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}

struct SurfaceCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(nsColor: .underPageBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
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
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .fontDesign(.rounded)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .foregroundStyle(tint)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CompactMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.6)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.title3.weight(.semibold))
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
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
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
