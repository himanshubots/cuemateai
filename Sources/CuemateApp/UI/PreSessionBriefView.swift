import SwiftUI

/// Read-only pre-meeting brief view.
/// Accepts a `MeetingBrief` directly — no dependency on AppModel.
/// Can be shown modally or inline before a session starts.
struct PreSessionBriefView: View {
    let brief: MeetingBrief

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                modeHeader
                goalSection
                openingSection
                focusAreasSection
                risksSection
                nextStepSection
                if !brief.documentHighlights.isEmpty {
                    documentHighlightsSection
                }
                if let note = brief.priorSessionNote {
                    priorSessionSection(note: note)
                }
            }
            .padding(16)
        }
        .frame(minWidth: 380)
    }

    // MARK: Mode header

    private var modeHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: modeIcon)
                .foregroundStyle(.secondary)
            Text(modeTitle)
                .font(.headline)
            Spacer()
            Text("Pre-meeting brief")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.bottom, 2)
    }

    // MARK: Goal

    private var goalSection: some View {
        BriefSectionBox(title: "Session Goal") {
            Text(brief.meetingGoal)
                .font(.callout)
        }
    }

    // MARK: Opening framing

    private var openingSection: some View {
        BriefSectionBox(title: "How to Open") {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Text(brief.openingFraming)
                    .font(.callout)
            }
        }
    }

    // MARK: Focus areas

    private var focusAreasSection: some View {
        BriefSectionBox(title: "Focus Areas") {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(brief.focusAreas, id: \.self) { area in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "scope")
                            .font(.caption2)
                            .foregroundStyle(Color.accentColor.opacity(0.8))
                            .padding(.top, 2)
                        Text(area)
                            .font(.callout)
                    }
                }
            }
        }
    }

    // MARK: Likely risks

    private var risksSection: some View {
        BriefSectionBox(title: "Watch For") {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(brief.likelyRisks, id: \.self) { risk in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.8))
                            .padding(.top, 2)
                        Text(risk)
                            .font(.callout)
                    }
                }
            }
        }
    }

    // MARK: Suggested next step (closing frame)

    private var nextStepSection: some View {
        BriefSectionBox(title: "Target Close") {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Text(brief.suggestedNextStep)
                    .font(.callout)
            }
        }
    }

    // MARK: Document highlights

    private var documentHighlightsSection: some View {
        BriefSectionBox(title: "From Your Documents") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(brief.documentHighlights, id: \.documentName) { highlight in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(highlight.documentName)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(highlight.signalMatch)
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.10))
                                .cornerRadius(3)
                        }
                        Text(highlight.relevantExcerpt)
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .padding(.leading, 16)
                    }
                    if highlight.documentName != brief.documentHighlights.last?.documentName {
                        Divider()
                    }
                }
            }
        }
    }

    // MARK: Prior session note

    private func priorSessionSection(note: String) -> some View {
        BriefSectionBox(title: "Prior Session") {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Helpers

    private var modeTitle: String {
        brief.meetingType
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private var modeIcon: String {
        switch brief.meetingType {
        case "sales":          return "chart.line.uptrend.xyaxis"
        case "demo":           return "play.rectangle"
        case "client-review":  return "checkmark.seal"
        case "interview":      return "person.crop.rectangle"
        case "internal-sync":  return "person.3"
        default:               return "calendar"
        }
    }
}
