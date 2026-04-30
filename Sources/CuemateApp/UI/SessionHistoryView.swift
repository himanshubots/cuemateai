import SwiftUI

// MARK: - Session history list

/// A self-contained session history browser.
/// Accepts sessions and documents as direct inputs — no dependency on AppModel.
struct SessionHistoryView: View {
    let sessions: [MeetingSessionRecord]
    let documents: [IngestedDocument]
    /// Single source of truth for which session is selected.
    /// Pass $model.selectedSessionID to drive selection from outside;
    /// defaults to a discardable local state via the @State-backed init.
    @Binding var selectedID: UUID?

    init(sessions: [MeetingSessionRecord], documents: [IngestedDocument], selectedID: Binding<UUID?> = .constant(nil)) {
        self.sessions = sessions
        self.documents = documents
        self._selectedID = selectedID
    }

    enum HistoryTab { case sessions, people }

    @State private var selectedTab: HistoryTab = .sessions
    @State private var selectedRelationshipID: String?

    private var sortedSessions: [MeetingSessionRecord] {
        sessions.sorted { ($0.endedAt ?? $0.startedAt) > ($1.endedAt ?? $1.startedAt) }
    }

    private var selectedSession: MeetingSessionRecord? {
        sessions.first { $0.id == selectedID }
    }

    private var relationships: [RelationshipSummary] {
        RelationshipTimelineBuilder().build(from: sessions)
    }

    private var selectedRelationship: RelationshipSummary? {
        relationships.first { $0.id == selectedRelationshipID }
    }

    var body: some View {
        HStack(spacing: 0) {
            leftColumn
                .frame(width: 226)
            Divider()
            rightPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Switch to Sessions tab whenever selection is driven externally while the view is mounted.
        .onChange(of: selectedID) { _, newID in
            if newID != nil { selectedTab = .sessions }
        }
    }

    // MARK: Left column

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabBar
            Divider()
            switch selectedTab {
            case .sessions: sessionList
            case .people:   peopleList
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton("Sessions", tab: .sessions)
            tabButton("People", tab: .people)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func tabButton(_ label: String, tab: HistoryTab) -> some View {
        let active = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .fontDesign(.rounded)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .foregroundStyle(active ? Color.accentColor : Color.primary.opacity(0.6))
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(active ? Color.accentColor.opacity(0.12) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Sessions list

    private var sessionList: some View {
        Group {
            if sortedSessions.isEmpty {
                VStack {
                    Text("No sessions yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .padding(12)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(sortedSessions) { session in
                            SessionRowView(session: session, isSelected: session.id == selectedID)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedID = session.id }
                        }
                    }
                    .padding(6)
                }
            }
        }
    }

    // MARK: People list

    private var peopleList: some View {
        Group {
            if relationships.isEmpty {
                VStack {
                    Text("Add a participant name to sessions to build a relationship timeline.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(relationships) { rel in
                            RelationshipRowView(rel: rel, isSelected: rel.id == selectedRelationshipID)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedRelationshipID = rel.id }
                        }
                    }
                    .padding(6)
                }
            }
        }
    }

    // MARK: Right pane

    @ViewBuilder
    private var rightPane: some View {
        switch selectedTab {
        case .sessions:
            if let session = selectedSession {
                SessionHistoryDetailView(session: session, documents: documents)
            } else {
                emptyDetail(text: "Select a session to view details.")
            }
        case .people:
            if let rel = selectedRelationship {
                RelationshipDetailView(rel: rel, documents: documents)
            } else {
                emptyDetail(text: "Select a contact to view their timeline.")
            }
        }
    }

    private func emptyDetail(text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .foregroundStyle(.secondary)
                .font(.callout)
            Spacer()
        }
    }
}

// MARK: - Relationship row

private struct RelationshipRowView: View {
    let rel: RelationshipSummary
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(rel.displayName)
                .font(.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(1)
            HStack(spacing: 4) {
                if !rel.company.isEmpty {
                    Text(rel.company)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text("\(rel.sessionCount) session\(rel.sessionCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if let outcome = rel.mostRecentOutcome {
                    Text(outcome.title)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(outcomeColor(outcome).opacity(0.75))
                        .cornerRadius(3)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        .cornerRadius(6)
    }

    private func outcomeColor(_ outcome: SessionOutcome) -> Color {
        switch outcome {
        case .pilot: .green
        case .followUp: .blue
        case .blocked: .red
        case .internalAction: .orange
        case .openRisk: .yellow
        case .unclear: .gray
        }
    }
}

// MARK: - Relationship detail

struct RelationshipDetailView: View {
    let rel: RelationshipSummary
    let documents: [IngestedDocument]

    @State private var selectedSessionID: UUID?

    private var selectedSession: MeetingSessionRecord? {
        rel.sessions.first { $0.id == selectedSessionID }
    }

    var body: some View {
        HStack(spacing: 0) {
            relationshipSummaryPanel
                .frame(width: 260)
            Divider()
            if let session = selectedSession {
                SessionHistoryDetailView(session: session, documents: documents)
            } else {
                VStack {
                    Spacer()
                    Text("Select a session to see details.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var relationshipSummaryPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                contactHeader
                if !rel.recurringTopics.isEmpty {
                    topicsSection
                }
                outcomesSection
                sessionsSection
            }
            .padding(16)
        }
    }

    private var contactHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(rel.displayName)
                .font(.title2.weight(.semibold))
                .fontDesign(.rounded)
            if !rel.company.isEmpty {
                Text(rel.company)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                Label("\(rel.sessionCount) session\(rel.sessionCount == 1 ? "" : "s")", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(shortDate(rel.lastContact), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var topicsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RECURRING TOPICS")
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(rel.recurringTopics, id: \.self) { topic in
                        Text(topic)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.10))
                            .cornerRadius(6)
                    }
                }
            }
        }
    }

    private var outcomesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PAST OUTCOMES")
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            let counted = outcomeBreakdown()
            if counted.isEmpty {
                Text("No outcomes recorded yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(counted, id: \.0.rawValue) { outcome, count in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(outcomeColor(outcome))
                                .frame(width: 6, height: 6)
                            Text("\(count)× \(outcome.title)")
                                .font(.caption.weight(.medium))
                        }
                    }
                }
            }
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SESSIONS")
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            ForEach(rel.sessions) { session in
                relationshipSessionRow(session)
                    .contentShape(Rectangle())
                    .onTapGesture { selectedSessionID = session.id }
            }
        }
    }

    private func relationshipSessionRow(_ session: MeetingSessionRecord) -> some View {
        let isSelected = session.id == selectedSessionID
        return HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                Text(shortDate(session.endedAt ?? session.startedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let outcome = session.sessionOutcome {
                Text(outcome.title)
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(outcomeColor(outcome).opacity(0.75))
                    .cornerRadius(3)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(nsColor: .controlBackgroundColor))
        )
    }

    private func outcomeBreakdown() -> [(SessionOutcome, Int)] {
        var freq: [SessionOutcome: Int] = [:]
        for outcome in rel.allOutcomes { freq[outcome, default: 0] += 1 }
        return freq.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    private func outcomeColor(_ outcome: SessionOutcome) -> Color {
        switch outcome {
        case .pilot: .green
        case .followUp: .blue
        case .blocked: .red
        case .internalAction: .orange
        case .openRisk: .yellow
        case .unclear: .gray
        }
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Session row

private struct SessionRowView: View {
    let session: MeetingSessionRecord
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.title)
                .font(.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(modeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let outcome = session.sessionOutcome {
                    Text(outcome.title)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(outcomeColor(outcome).opacity(0.75))
                        .cornerRadius(3)
                }
                Spacer()
                Text(shortDate(session.endedAt ?? session.startedAt))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        .cornerRadius(6)
    }

    private func outcomeColor(_ outcome: SessionOutcome) -> Color {
        switch outcome {
        case .pilot:          return .green
        case .followUp:       return .blue
        case .blocked:        return .red
        case .internalAction: return .orange
        case .openRisk:       return .yellow
        case .unclear:        return .gray
        }
    }

    private var modeLabel: String {
        session.configuration.meetingType
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - Session history detail

/// Full detail view for a single completed session.
/// Surfaces summary, action items, follow-up draft, stored brief, and follow-up artifact.
/// Named SessionHistoryDetailView to avoid collision with the live SessionDetailView in RootView.
struct SessionHistoryDetailView: View {
    let session: MeetingSessionRecord
    let documents: [IngestedDocument]

    private var finalTranscriptSegments: [TranscriptSegment] {
        Array(session.transcriptSegments.filter(\.isFinal).prefix(12))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection

                if let summary = session.summary {
                    overviewSection(summary)
                }

                transcriptSection

                if !session.followUpNotes.isEmpty {
                    BriefSectionBox(title: "Notes") {
                        Text(session.followUpNotes)
                            .font(.callout)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.title)
                .font(.title3)
                .fontWeight(.semibold)
            HStack(spacing: 10) {
                Label(modeLabel, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let ended = session.endedAt {
                    Label(fullDate(ended), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(session.transcriptSegments.count) segments")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if session.endedAt != nil {
                HStack(spacing: 8) {
                    Text("Outcome:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Outcome", selection: Binding(
                        get: { session.sessionOutcome ?? .unclear },
                        set: { _ in }
                    )) {
                        ForEach(SessionOutcome.allCases, id: \.self) { outcome in
                            Text(outcome.title).tag(outcome)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.caption)
                    .disabled(true)
                    if let outcome = session.sessionOutcome {
                        Text(outcome.title)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(outcomeAccentColor(outcome))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    private func outcomeAccentColor(_ outcome: SessionOutcome) -> Color {
        switch outcome {
        case .pilot:          return .green
        case .followUp:       return .blue
        case .blocked:        return .red
        case .internalAction: return .orange
        case .openRisk:       return Color(red: 0.8, green: 0.7, blue: 0.0)
        case .unclear:        return .gray
        }
    }

    // MARK: Overview

    private func overviewSection(_ summary: MeetingSummary) -> some View {
        BriefSectionBox(title: "Conversation") {
            VStack(alignment: .leading, spacing: 8) {
                Text(summary.overview)
                    .font(.callout)
                if !summary.keyTopics.isEmpty {
                    Divider()
                    HistoryTagRowView(tags: summary.keyTopics)
                }
            }
        }
    }

    private var transcriptSection: some View {
        BriefSectionBox(title: "Transcript") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(finalTranscriptSegments) { segment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(segment.speaker)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(segment.text)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if segment.id != finalTranscriptSegments.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: Helpers

    private var modeLabel: String {
        session.configuration.meetingType
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func fullDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Shared card component

/// Titled card used across `SessionDetailView` and `PreSessionBriefView`.
struct BriefSectionBox<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .kerning(0.5)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

// MARK: - Private sub-components

private struct HistoryLabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.callout)
        }
    }
}

private struct HistoryTagRowView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.10))
                        .cornerRadius(4)
                }
            }
        }
    }
}
