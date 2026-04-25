import SwiftUI

// MARK: - Session history list

/// A self-contained session history browser.
/// Accepts sessions and documents as direct inputs — no dependency on AppModel.
struct SessionHistoryView: View {
    let sessions: [MeetingSessionRecord]
    let documents: [IngestedDocument]

    @State private var selectedID: UUID?

    private var sortedSessions: [MeetingSessionRecord] {
        sessions.sorted { ($0.endedAt ?? $0.startedAt) > ($1.endedAt ?? $1.startedAt) }
    }

    private var selectedSession: MeetingSessionRecord? {
        sessions.first { $0.id == selectedID }
    }

    var body: some View {
        HStack(spacing: 0) {
            sessionList
                .frame(width: 220)
            Divider()
            detailPane
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: List column

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Sessions")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            Divider()
            if sortedSessions.isEmpty {
                Text("No sessions yet.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(12)
                Spacer()
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

    // MARK: Detail column

    @ViewBuilder
    private var detailPane: some View {
        if let session = selectedSession {
            SessionHistoryDetailView(session: session, documents: documents)
        } else {
            VStack {
                Spacer()
                Text("Select a session to view details.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Spacer()
            }
        }
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection

                if let summary = session.summary {
                    overviewSection(summary)
                    if !summary.actionItems.isEmpty {
                        actionItemsSection(summary.actionItems)
                    }
                    if !summary.decisionSummary.isEmpty {
                        BriefSectionBox(title: "Decision") {
                            Text(summary.decisionSummary)
                                .font(.callout)
                        }
                    }
                    followUpSection(summary)
                }

                if let brief = session.brief {
                    storedBriefSection(brief)
                }

                if let artifact = session.followUpArtifact {
                    savedArtifactSection(artifact)
                }

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
        }
    }

    // MARK: Overview

    private func overviewSection(_ summary: MeetingSummary) -> some View {
        BriefSectionBox(title: "Overview") {
            VStack(alignment: .leading, spacing: 8) {
                Text(summary.overview)
                    .font(.callout)
                if !summary.outcomeNote.isEmpty {
                    Divider()
                    Label(summary.outcomeNote, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !summary.keyTopics.isEmpty {
                    Divider()
                    HistoryTagRowView(tags: summary.keyTopics)
                }
            }
        }
    }

    // MARK: Action items

    private func actionItemsSection(_ items: [String]) -> some View {
        BriefSectionBox(title: "Action Items") {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(item)
                            .font(.callout)
                    }
                }
            }
        }
    }

    // MARK: Follow-up draft

    private func followUpSection(_ summary: MeetingSummary) -> some View {
        BriefSectionBox(title: "Follow-up Draft") {
            VStack(alignment: .leading, spacing: 6) {
                if !summary.followUpSubject.isEmpty {
                    HStack(spacing: 4) {
                        Text("Subject:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(summary.followUpSubject)
                            .font(.caption)
                    }
                    Divider()
                }
                Text(summary.followUpDraft)
                    .font(.callout)
            }
        }
    }

    // MARK: Stored pre-meeting brief (if any)

    private func storedBriefSection(_ brief: MeetingBrief) -> some View {
        BriefSectionBox(title: "Pre-meeting Brief Used") {
            VStack(alignment: .leading, spacing: 8) {
                HistoryLabeledRow(label: "Goal", value: brief.meetingGoal)
                if !brief.focusAreas.isEmpty {
                    HistoryLabeledRow(
                        label: "Focus",
                        value: brief.focusAreas.joined(separator: " · ")
                    )
                }
                if !brief.openingFraming.isEmpty {
                    HistoryLabeledRow(label: "Opening", value: brief.openingFraming)
                }
                if let note = brief.priorSessionNote {
                    Divider()
                    HistoryLabeledRow(label: "Prior", value: note)
                }
            }
        }
    }

    // MARK: Saved follow-up artifact (if any)

    private func savedArtifactSection(_ artifact: StoredFollowUpArtifact) -> some View {
        BriefSectionBox(title: "Saved Follow-up") {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("Subject:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(artifact.subject)
                        .font(.caption)
                }
                Divider()
                Text(artifact.body)
                    .font(.callout)
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
