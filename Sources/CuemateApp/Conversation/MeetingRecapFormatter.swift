import Foundation

/// Builds a mode-aware structured overview paragraph for post-meeting summaries.
/// Replaces the naive "first N words of transcript" approach with framing that
/// reflects what the meeting mode cares about.
struct MeetingRecapFormatter: Sendable {

    struct RecapInput: Sendable {
        let meetingType: String
        let transcriptTexts: [String]
        let signals: MeetingModePromptHelper.TranscriptSignals
        let transcriptCount: Int
        let guidanceCount: Int
    }

    func buildOverview(from input: RecapInput) -> String {
        let lead = modeLead(meetingType: input.meetingType)
        let excerpt = transcriptExcerpt(from: input.transcriptTexts, wordLimit: 22)
        let signalNote = buildSignalNote(signals: input.signals, meetingType: input.meetingType)
        let statsNote = buildStatsNote(transcriptCount: input.transcriptCount, guidanceCount: input.guidanceCount)

        var parts: [String] = [lead]
        if !excerpt.isEmpty { parts.append(excerpt) }
        if !signalNote.isEmpty { parts.append(signalNote) }
        parts.append(statsNote)

        return parts.joined(separator: " ")
    }

    // MARK: - Mode lead

    private func modeLead(meetingType: String) -> String {
        switch meetingType {
        case "sales":
            return "Sales call."
        case "demo":
            return "Demo session."
        case "client-review":
            return "Client review."
        case "interview":
            return "Interview."
        case "internal-sync":
            return "Internal sync."
        default:
            return "Meeting."
        }
    }

    // MARK: - Transcript excerpt

    private func transcriptExcerpt(from texts: [String], wordLimit: Int) -> String {
        let joined = texts.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let words = joined.split(whereSeparator: \.isWhitespace).prefix(wordLimit)
        guard !words.isEmpty else { return "" }
        let snippet = words.joined(separator: " ")
        return "The conversation covered: \(snippet)\(words.count == wordLimit ? "…" : ".")"
    }

    // MARK: - Signal note (most prominent signal per mode)

    private func buildSignalNote(
        signals: MeetingModePromptHelper.TranscriptSignals,
        meetingType: String
    ) -> String {
        // High-value combos first
        if signals.hasPilotMention && signals.hasBudgetMention {
            return "Budget and pilot scope were both raised."
        }
        if signals.hasPilotMention && signals.hasTimelineMention {
            return "A pilot with a rough timeline was discussed."
        }
        if signals.hasDecisionSignal && signals.hasBlockerSignal {
            return "A decision was made and a blocker was identified."
        }

        // Mode-specific single signals
        switch meetingType {
        case "sales":
            if signals.hasPilotMention { return "A pilot-style next step was mentioned." }
            if signals.hasBudgetMention { return "Budget or cost was part of the discussion." }
            if signals.hasTimelineMention { return "Timeline or urgency came up." }
            if signals.hasConcernSignal { return "A concern or objection was raised." }
        case "demo":
            if signals.hasOnboardingSignal { return "Onboarding or getting started was discussed." }
            if signals.hasConcernSignal { return "A question or concern was raised during the demo." }
        case "client-review":
            if signals.hasConcernSignal { return "An open risk or concern was raised." }
            if signals.hasDecisionSignal { return "At least one decision or confirmation was reached." }
            if signals.hasTimelineMention { return "Timing or a milestone deadline came up." }
        case "interview":
            if signals.hasQuestionSignal { return "The conversation included at least one direct question." }
            if signals.hasCommitmentSignal { return "A commitment or next step was mentioned." }
        case "internal-sync":
            if signals.hasBlockerSignal { return "A blocker was surfaced during the sync." }
            if signals.hasDecisionSignal { return "At least one decision was made or confirmed." }
            if signals.hasCommitmentSignal { return "Commitments or ownership were discussed." }
        default:
            break
        }

        // Generic cross-mode fallbacks
        if signals.hasCommitmentSignal { return "At least one commitment was made." }
        if signals.hasSendRequest { return "Materials or a follow-up document were requested." }
        if signals.hasFollowUpMention { return "A follow-up was planned." }

        return ""
    }

    // MARK: - Stats note

    private func buildStatsNote(transcriptCount: Int, guidanceCount: Int) -> String {
        let segments = "\(transcriptCount) transcript segment\(transcriptCount == 1 ? "" : "s")"
        let guidance = "\(guidanceCount) live guidance moment\(guidanceCount == 1 ? "" : "s")"
        return "\(segments.capitalized) and \(guidance) recorded."
    }
}
