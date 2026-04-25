import Foundation

// MARK: - Model

/// A structured pre-meeting brief produced before a session starts.
/// Covers what to aim for, what to watch, and what context is relevant.
struct MeetingBrief: Codable, Sendable, Equatable {
    /// The meeting mode this brief was produced for.
    var meetingType: String
    /// The primary suggested goal for this session.
    var meetingGoal: String
    /// 3–5 areas to drive or monitor during the meeting.
    var focusAreas: [String]
    /// 2–3 likely objections, risks, or blockers to anticipate.
    var likelyRisks: [String]
    /// How to frame the desired outcome when closing the meeting.
    var suggestedNextStep: String
    /// How to open the meeting effectively.
    var openingFraming: String
    /// Relevant signals surfaced from attached documents.
    var documentHighlights: [DocumentHighlight]
    /// Note drawn from the most recent prior session of the same type.
    var priorSessionNote: String?
    /// When this brief was generated.
    var generatedAt: Date

    struct DocumentHighlight: Codable, Sendable, Equatable {
        /// Source document name.
        var documentName: String
        /// Short excerpt most relevant to this meeting mode.
        var relevantExcerpt: String
        /// The mode signal or focus area this excerpt addresses.
        var signalMatch: String
    }
}

// MARK: - Builder

/// Builds a `MeetingBrief` from configuration, attached documents, and prior sessions.
/// Pure and `Sendable` — no I/O. Caller provides all inputs.
struct MeetingBriefBuilder: Sendable {
    private let modeHelper = MeetingModePromptHelper()

    struct BriefInput: Sendable {
        /// Configuration for the upcoming session.
        let configuration: MeetingConfiguration
        /// Documents attached to this session.
        let attachedDocuments: [IngestedDocument]
        /// All available document chunks; filtered internally to attached docs.
        let documentChunks: [DocumentChunk]
        /// Prior completed sessions used for continuity context.
        let priorSessions: [MeetingSessionRecord]
    }

    func build(from input: BriefInput) -> MeetingBrief {
        let meetingType = input.configuration.meetingType

        let focusAreas = buildFocusAreas(
            meetingType: meetingType,
            documents: input.attachedDocuments,
            chunks: input.documentChunks
        )
        let highlights = buildDocumentHighlights(
            meetingType: meetingType,
            documents: input.attachedDocuments,
            chunks: input.documentChunks
        )
        let priorNote = extractPriorSessionNote(
            from: input.priorSessions,
            meetingType: meetingType
        )

        return MeetingBrief(
            meetingType: meetingType,
            meetingGoal: buildMeetingGoal(for: meetingType),
            focusAreas: focusAreas,
            likelyRisks: buildLikelyRisks(for: meetingType),
            suggestedNextStep: buildSuggestedNextStep(for: meetingType),
            openingFraming: buildOpeningFraming(for: meetingType),
            documentHighlights: highlights,
            priorSessionNote: priorNote,
            generatedAt: Date()
        )
    }

    // MARK: - Meeting goal

    private func buildMeetingGoal(for meetingType: String) -> String {
        switch meetingType {
        case "sales":
            return "Qualify the path forward and define the smallest concrete next step toward a pilot or decision."
        case "demo":
            return "Showcase the highest-value workflow and identify the team's top integration or adoption interest."
        case "client-review":
            return "Confirm progress made, surface the top open risk, and close on one accountable next action."
        case "interview":
            return "Make the role-fit case clearly with one strong example, and leave with a defined next step."
        case "internal-sync":
            return "Align on the key decision, confirm ownership, and unblock the critical path before the meeting ends."
        default:
            return "Advance the conversation and leave with at least one clear, named next move."
        }
    }

    // MARK: - Focus areas

    private func buildFocusAreas(
        meetingType: String,
        documents: [IngestedDocument],
        chunks: [DocumentChunk]
    ) -> [String] {
        // Seed from mode helper — consistent with summary focus
        var areas = modeHelper.summaryFocusAreas(for: meetingType)

        // Enrich up to 2 more areas if documents contain relevant signals
        if !documents.isEmpty {
            let docSignals = documentDrivenFocusSignals(
                meetingType: meetingType,
                documents: documents,
                chunks: chunks
            )
            for signal in docSignals where !areas.contains(signal) {
                areas.append(signal)
            }
        }

        return Array(areas.prefix(5))
    }

    private func documentDrivenFocusSignals(
        meetingType: String,
        documents: [IngestedDocument],
        chunks: [DocumentChunk]
    ) -> [String] {
        let signals = modeHelper.successSignals(for: meetingType)
        let attachedIDs = Set(documents.map(\.id))
        let attachedChunks = chunks.filter { attachedIDs.contains($0.documentID) }
        var found: [String] = []

        for signal in signals {
            let hit = attachedChunks.contains { $0.text.lowercased().contains(signal) }
            if hit {
                found.append("Document material covers: \(signal)")
            }
            if found.count >= 2 { break }
        }
        return found
    }

    // MARK: - Likely risks

    private func buildLikelyRisks(for meetingType: String) -> [String] {
        switch meetingType {
        case "sales":
            return [
                "Budget or procurement may be a gating factor not yet surfaced.",
                "The decision-maker may not be in the room today.",
                "Timeline expectations on both sides may be misaligned.",
            ]
        case "demo":
            return [
                "The demo workflow may not map cleanly to their current process.",
                "Integration complexity may surface as an objection mid-demo.",
                "The team may want to see a use case you are not prepared for today.",
            ]
        case "client-review":
            return [
                "Progress may not feel as visible to the client as it does internally.",
                "An undiscussed risk or scope item may surface and shift the tone.",
                "Timeline or delivery expectations may have drifted since the last review.",
            ]
        case "interview":
            return [
                "A follow-up question may go deeper than the prepared example allows.",
                "The role requirements may be more specific or narrower than expected.",
                "A gap in direct experience may be probed more than anticipated.",
            ]
        case "internal-sync":
            return [
                "A blocker may emerge that stalls the decision.",
                "Ownership of a key action may be unclear or contested.",
                "External dependencies may introduce unexpected delay.",
            ]
        default:
            return [
                "The conversation may drift from the primary goal.",
                "A commitment or decision may be harder to reach than expected.",
            ]
        }
    }

    // MARK: - Suggested next step

    private func buildSuggestedNextStep(for meetingType: String) -> String {
        switch meetingType {
        case "sales":
            return "Ask what would need to be true for them to move forward with a pilot in the next 30 days."
        case "demo":
            return "Ask which workflow or feature they would want to integrate or explore first after today."
        case "client-review":
            return "Agree on one concrete owner and deadline for the top open item before closing the review."
        case "interview":
            return "Ask about the next step in their process before the meeting ends — and express clear interest."
        case "internal-sync":
            return "Close with a named decision, a confirmed owner, and a deadline for the top open item."
        default:
            return "End with one named next action, a clear owner, and a rough timeline agreed by both sides."
        }
    }

    // MARK: - Opening framing

    private func buildOpeningFraming(for meetingType: String) -> String {
        switch meetingType {
        case "sales":
            return "Open by anchoring on the business problem they care most about — not the product. One sharp question that shows you understood their situation before the call."
        case "demo":
            return "Open by confirming which workflow or use case they most want to see today. Align on scope before the first screen share."
        case "client-review":
            return "Open by acknowledging specific progress made since the last review. Set a positive but honest tone before moving to open items."
        case "interview":
            return "Open by briefly confirming you understand the role and what success looks like in the first 90 days. Signal that you are here to discuss fit — not to recite a CV."
        case "internal-sync":
            return "Open by naming the decision or outcome this sync is meant to produce. Make the goal explicit before diving into updates."
        default:
            return "Open by stating the one thing you want to make sure gets resolved or advanced by the end of the meeting."
        }
    }

    // MARK: - Document highlights

    private func buildDocumentHighlights(
        meetingType: String,
        documents: [IngestedDocument],
        chunks: [DocumentChunk]
    ) -> [MeetingBrief.DocumentHighlight] {
        guard !documents.isEmpty else { return [] }

        let signals = modeHelper.successSignals(for: meetingType)
        let chunksByDocument = Dictionary(grouping: chunks, by: \.documentID)
        var highlights: [MeetingBrief.DocumentHighlight] = []

        for document in documents.prefix(4) {
            guard let docChunks = chunksByDocument[document.id], !docChunks.isEmpty else { continue }

            let sorted = docChunks.sorted { $0.index < $1.index }

            if let (chunk, matchedSignal) = findBestChunk(in: sorted, matching: signals) {
                let excerpt = extractExcerpt(from: chunk.text, near: matchedSignal, maxWords: 20)
                highlights.append(.init(
                    documentName: document.fileName,
                    relevantExcerpt: excerpt,
                    signalMatch: matchedSignal.capitalized
                ))
            } else if let first = sorted.first {
                let excerpt = extractExcerpt(from: first.text, near: nil, maxWords: 20)
                highlights.append(.init(
                    documentName: document.fileName,
                    relevantExcerpt: excerpt,
                    signalMatch: "General context"
                ))
            }

            if highlights.count >= 3 { break }
        }

        return highlights
    }

    private func findBestChunk(
        in chunks: [DocumentChunk],
        matching signals: [String]
    ) -> (DocumentChunk, String)? {
        for signal in signals {
            for chunk in chunks {
                if chunk.text.lowercased().contains(signal) {
                    return (chunk, signal)
                }
            }
        }
        return nil
    }

    private func extractExcerpt(from text: String, near signal: String?, maxWords: Int) -> String {
        let words = text.split(whereSeparator: \.isWhitespace)

        if let signal = signal,
           let range = text.lowercased().range(of: signal) {
            let prefixText = String(text[..<range.lowerBound])
            let wordOffset = max(0, prefixText.split(whereSeparator: \.isWhitespace).count - 2)
            let window = Array(words.dropFirst(wordOffset).prefix(maxWords))
            let joined = window.joined(separator: " ")
            return joined.isEmpty ? String(words.prefix(maxWords).joined(separator: " ")) : joined + "…"
        }

        let result = Array(words.prefix(maxWords)).joined(separator: " ")
        return words.count > maxWords ? result + "…" : result + "."
    }

    // MARK: - Prior session note

    private func extractPriorSessionNote(
        from sessions: [MeetingSessionRecord],
        meetingType: String
    ) -> String? {
        let completed = sessions
            .filter {
                $0.configuration.meetingType == meetingType
                    && $0.endedAt != nil
                    && $0.summary != nil
            }
            .sorted { ($0.endedAt ?? .distantPast) > ($1.endedAt ?? .distantPast) }

        guard let prior = completed.first, let summary = prior.summary else { return nil }

        let dateStr = briefDateString(prior.endedAt ?? prior.startedAt)
        let modeLabel = meetingType.replacingOccurrences(of: "-", with: " ")

        if !summary.decisionSummary.isEmpty {
            return "Last \(modeLabel) (\(dateStr)): \(summary.decisionSummary)"
        }
        if !summary.outcomeNote.isEmpty {
            return "Last \(modeLabel) (\(dateStr)): \(summary.outcomeNote)"
        }
        if let firstAction = summary.actionItems.first {
            return "Last \(modeLabel) (\(dateStr)) left off with: \(firstAction)"
        }

        let segments = prior.transcriptSegments.count
        return "Last \(modeLabel) on \(dateStr) — \(segments) segment\(segments == 1 ? "" : "s") recorded."
    }

    private func briefDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - BriefInput convenience factory

extension MeetingBriefBuilder.BriefInput {
    /// Builds a `BriefInput` from a `DocumentLibrarySnapshot` and a list of session document IDs.
    /// Filters the snapshot internally so call sites do not need to pre-filter docs or chunks.
    ///
    /// Usage:
    /// ```swift
    /// let input = MeetingBriefBuilder.BriefInput.from(
    ///     configuration: session.configuration,
    ///     snapshot: librarySnapshot,
    ///     documentIDs: session.documentIDs,
    ///     priorSessions: allSessions
    /// )
    /// let brief = MeetingBriefBuilder().build(from: input)
    /// ```
    static func from(
        configuration: MeetingConfiguration,
        snapshot: DocumentLibrarySnapshot,
        documentIDs: [UUID],
        priorSessions: [MeetingSessionRecord]
    ) -> Self {
        let idSet = Set(documentIDs)
        let attached = snapshot.documents.filter { idSet.contains($0.id) }
        return Self(
            configuration: configuration,
            attachedDocuments: attached,
            documentChunks: snapshot.chunks,
            priorSessions: priorSessions
        )
    }
}
