import Foundation

struct MeetingSummary: Codable, Sendable, Equatable {
    var overview: String
    var keyTopics: [String]
    var actionItems: [String]
    var outcomeNote: String
    /// The full formatted follow-up (subject line + body) for backward compatibility.
    var followUpDraft: String
    /// Subject line extracted as a first-class field for UI display.
    var followUpSubject: String
    var decisionSummary: String

    init(
        overview: String,
        keyTopics: [String],
        actionItems: [String],
        outcomeNote: String,
        followUpDraft: String,
        followUpSubject: String = "",
        decisionSummary: String
    ) {
        self.overview = overview
        self.keyTopics = keyTopics
        self.actionItems = actionItems
        self.outcomeNote = outcomeNote
        self.followUpDraft = followUpDraft
        self.followUpSubject = followUpSubject
        self.decisionSummary = decisionSummary
    }

    /// Custom decoder to stay backward compatible with sessions saved before
    /// `followUpSubject` was added — those will decode to an empty string.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        overview = try c.decode(String.self, forKey: .overview)
        keyTopics = try c.decode([String].self, forKey: .keyTopics)
        actionItems = try c.decode([String].self, forKey: .actionItems)
        outcomeNote = try c.decode(String.self, forKey: .outcomeNote)
        followUpDraft = try c.decode(String.self, forKey: .followUpDraft)
        followUpSubject = (try? c.decode(String.self, forKey: .followUpSubject)) ?? ""
        decisionSummary = try c.decode(String.self, forKey: .decisionSummary)
    }
}

struct PostMeetingSummaryService: Sendable {
    private let modeHelper = MeetingModePromptHelper()
    private let draftBuilder = FollowUpDraftBuilder()
    private let recapFormatter = MeetingRecapFormatter()

    func generateSummary(for session: MeetingSessionRecord, documents: [IngestedDocument]) -> MeetingSummary {
        let transcriptTexts = session.transcriptSegments
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.text)

        let fullTranscript = transcriptTexts.joined(separator: " ")
        let signals = modeHelper.extractSignals(from: fullTranscript)

        // Mode-aware structured overview via MeetingRecapFormatter
        let recapInput = MeetingRecapFormatter.RecapInput(
            meetingType: session.configuration.meetingType,
            transcriptTexts: transcriptTexts,
            signals: signals,
            transcriptCount: session.transcriptSegments.count,
            guidanceCount: session.guidanceHistory.count
        )
        let overview = recapFormatter.buildOverview(from: recapInput)

        let keyTopics = extractKeyTopics(from: transcriptTexts, meetingType: session.configuration.meetingType)
        let actionItems = buildActionItems(from: session, documents: documents, signals: signals, transcriptTexts: transcriptTexts)
        let outcomeNote = deriveOutcome(from: session, signals: signals)
        let decisionSummary = buildDecisionSummary(for: session, signals: signals)

        let draftInput = FollowUpDraftBuilder.DraftInput(
            meetingType: session.configuration.meetingType,
            speakerName: session.configuration.speakerName,
            actionItems: actionItems,
            transcriptText: fullTranscript,
            keyTopics: keyTopics,
            decisionSummary: decisionSummary
        )
        let builtDraft = draftBuilder.build(from: draftInput)

        return MeetingSummary(
            overview: overview,
            keyTopics: Array(keyTopics.prefix(5)),
            actionItems: Array(actionItems.prefix(5)),
            outcomeNote: outcomeNote,
            followUpDraft: builtDraft.formatted,
            followUpSubject: builtDraft.subject,
            decisionSummary: decisionSummary
        )
    }

    // MARK: - Key topic extraction

    private func extractKeyTopics(from texts: [String], meetingType: String) -> [String] {
        let tokens = texts.flatMap { tokenize($0) }

        // Score unigrams
        var unigramCounts = Dictionary(tokens.map { ($0, 1) }, uniquingKeysWith: +)

        // Boost tokens that match mode success signals
        let signals = modeHelper.successSignals(for: meetingType)
        for signal in signals {
            let normalized = signal.lowercased().replacingOccurrences(of: " ", with: "")
            if let count = unigramCounts[normalized] {
                unigramCounts[normalized] = count + 3
            }
        }

        let filteredUnigrams = unigramCounts
            .filter { token, _ in
                token.count > 4 && !stopWords.contains(token)
            }
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .map(\.key)
            .map { $0.capitalized }

        // Extract meaningful bigrams (two-word phrases)
        let bigrams = extractBigrams(from: texts)

        // Merge bigrams first (more specific), then fill with unigrams
        var result: [String] = bigrams.prefix(3).map { $0 }
        for token in filteredUnigrams {
            if result.count >= 6 { break }
            // Skip if already covered by a bigram
            let alreadyCovered = result.contains { $0.lowercased().contains(token.lowercased()) }
            if !alreadyCovered {
                result.append(token)
            }
        }

        return result
    }

    private func extractBigrams(from texts: [String]) -> [String] {
        var bigramCounts: [String: Int] = [:]

        for text in texts {
            let words = tokenize(text).filter { $0.count > 3 && !stopWords.contains($0) }
            for i in 0..<(words.count - 1) {
                let bigram = "\(words[i].capitalized) \(words[i + 1].capitalized)"
                bigramCounts[bigram, default: 0] += 1
            }
        }

        return bigramCounts
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .map(\.key)
    }

    // MARK: - Action items

    private func buildActionItems(
        from session: MeetingSessionRecord,
        documents: [IngestedDocument],
        signals: MeetingModePromptHelper.TranscriptSignals,
        transcriptTexts: [String]
    ) -> [String] {
        var items: [String] = []

        // Guidance-derived action (most specific — from live coaching)
        if let next = session.guidanceHistory.last?.content.next, !next.isEmpty {
            items.append(next)
        }

        // Signal-specific items (cross-mode, high precision)
        if signals.hasSendRequest {
            items.append("Send the requested materials or follow-up document.")
        }

        if signals.hasPilotMention {
            items.append("Define the pilot scope, timeline, and success criteria.")
        } else if signals.hasBudgetMention {
            items.append("Clarify the budget range and expected rollout size.")
        }

        if signals.hasTimelineMention {
            items.append("Confirm the timeline discussed and the first hard deadline.")
        }

        if signals.hasBlockerSignal {
            items.append("Identify and resolve the blocker raised in the meeting.")
        }

        if signals.hasConcernSignal && !signals.hasBlockerSignal {
            items.append("Address the concern raised and share a short written response.")
        }

        // Mode-specific items (fallback when signals don't fire)
        appendModeSpecificItems(
            to: &items,
            meetingType: session.configuration.meetingType,
            signals: signals
        )

        // Document attachment reminder
        if !session.documentIDs.isEmpty {
            let attachedCount = documents.filter { session.documentIDs.contains($0.id) }.count
            if attachedCount > 0 {
                items.append("Review the \(attachedCount) attached document\(attachedCount == 1 ? "" : "s") before the next meeting.")
            }
        }

        // Fallback
        if items.isEmpty {
            items.append("Review the meeting transcript and identify the clearest next action.")
        }

        return deduplicated(items)
    }

    private func appendModeSpecificItems(
        to items: inout [String],
        meetingType: String,
        signals: MeetingModePromptHelper.TranscriptSignals
    ) {
        switch meetingType {
        case "sales":
            if !signals.hasPilotMention && !signals.hasBudgetMention {
                items.append("Identify the smallest high-value starting point for a next step.")
            }
            items.append("Confirm whether procurement or a decision-maker needs to be looped in.")
        case "demo":
            items.append("Note which workflow generated the most engagement.")
            if signals.hasOnboardingSignal {
                items.append("Draft a lightweight onboarding path for the highest-interest workflow.")
            }
        case "client-review":
            items.append("Document the main open risk and the owner responsible for resolving it.")
            items.append("Share a written status update before the next review date.")
        case "interview":
            items.append("Prepare a stronger example for the topic that came up most prominently.")
            items.append("Send a thank-you note within 24 hours with one reinforcing signal.")
        case "internal-sync":
            items.append("Confirm owners and deadlines for each action item named in the sync.")
            if signals.hasBlockerSignal {
                items.append("Escalate the blocker to the appropriate stakeholder.")
            }
        default:
            items.append("Review the meeting transcript and pick the best follow-up action.")
        }
    }

    // MARK: - Outcome note

    private func deriveOutcome(
        from session: MeetingSessionRecord,
        signals: MeetingModePromptHelper.TranscriptSignals
    ) -> String {
        let meetingType = session.configuration.meetingType

        // High-signal combinations first
        if signals.hasPilotMention && signals.hasTimelineMention {
            return "The conversation moved toward a pilot with a rough timeline — strong buying signal."
        }
        if signals.hasPilotMention && signals.hasBudgetMention {
            return "Budget and pilot scope were both on the table — the deal is in active evaluation."
        }
        if signals.hasDecisionSignal && meetingType == "internal-sync" {
            return "At least one decision was made in this sync — confirm ownership before the thread cools."
        }
        if signals.hasBlockerSignal && meetingType == "internal-sync" {
            return "A blocker surfaced in the sync — unblocking this is the critical next action."
        }
        if signals.hasConcernSignal && (meetingType == "sales" || meetingType == "client-review") {
            return "A concern or risk was raised — addressing it directly will determine the next move."
        }
        if signals.hasCommitmentSignal {
            return "At least one explicit commitment was made — track it before the next touchpoint."
        }

        // Transcript signal fallbacks
        if signals.hasPilotMention {
            return "The conversation pointed toward a pilot-style next step."
        }
        if signals.hasFollowUpMention || signals.hasSendRequest {
            return "A follow-up or material handoff is expected from this meeting."
        }
        if signals.hasTimelineMention {
            return "Timing and near-term execution were prominent — the urgency is real."
        }

        // Mode-specific fallbacks
        if session.guidanceHistory.isEmpty {
            return "The session captured conversation context with minimal live guidance recorded."
        }

        switch meetingType {
        case "sales":
            return "The session built context for a sales conversation. The next step is to qualify the path forward."
        case "demo":
            return "The demo ran with live context captured. The next step is to note what resonated most."
        case "client-review":
            return "The review session completed. Progress and open risks were the main themes."
        case "interview":
            return "The interview session closed. The next step is a timely follow-up that reinforces fit."
        case "internal-sync":
            return "The sync captured conversation context. Decisions and owners should be confirmed in writing."
        default:
            return "The session captured both conversation context and live guidance for later review."
        }
    }

    // MARK: - Decision summary

    private func buildDecisionSummary(
        for session: MeetingSessionRecord,
        signals: MeetingModePromptHelper.TranscriptSignals
    ) -> String {
        let meetingType = session.configuration.meetingType

        if signals.hasDecisionSignal && signals.hasPilotMention {
            return "A pilot decision appears to have been reached. Confirm scope and timeline in writing."
        }
        if signals.hasDecisionSignal {
            return "At least one decision was confirmed in the meeting. Document the decision and who owns the next action."
        }
        if signals.hasPilotMention {
            return "The conversation leaned toward a pilot-style next step. Scope and timeline still need confirmation."
        }
        if signals.hasFollowUpMention || signals.hasSendRequest {
            return "The meeting ended with a likely follow-up or material handoff as the key next move."
        }
        if signals.hasTimelineMention {
            return "Timing and near-term execution are the key decision variable coming out of this meeting."
        }
        if signals.hasBlockerSignal {
            return "A blocker is the primary obstacle — the key decision is who unblocks it and by when."
        }

        switch meetingType {
        case "sales":
            return "The key outcome is whether this can move toward a qualified next step with a clear owner."
        case "demo":
            return "The key outcome is which workflow or product path should be shown or explored next."
        case "client-review":
            return "The key outcome is progress clarity, the top open risk, and the next accountable action."
        case "interview":
            return "The key outcome is whether the discussion strengthened fit and created a clear path to the next conversation."
        case "internal-sync":
            return "The key outcome is whether ownership and the next action became explicit before the meeting ended."
        default:
            return "The key outcome is the clearest next move coming out of the discussion."
        }
    }

    // MARK: - Helpers

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    private func deduplicated(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { value in
            seen.insert(value).inserted
        }
    }

    private let stopWords: Set<String> = [
        "about", "after", "again", "because", "before", "could", "there", "their",
        "would", "should", "while", "where", "which", "thanks", "based", "start",
        "still", "needs", "using", "local", "meeting", "answer", "clear", "first",
        "later", "right", "through", "going", "think", "just", "know", "like",
        "have", "that", "with", "this", "will", "from", "were", "been", "they",
        "what", "when", "then", "also", "some", "more", "than", "very", "into"
    ]
}
