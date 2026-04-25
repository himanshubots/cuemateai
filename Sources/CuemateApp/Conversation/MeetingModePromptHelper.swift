import Foundation

/// Read-only guidance for each meeting mode.
/// Single source of truth for mode-specific coaching, prompt text, and transcript-signal extraction.
/// Used by ConversationEngine, prompt builders, and PostMeetingSummaryService.
struct MeetingModePromptHelper: Sendable {

    // MARK: - Coaching objectives

    /// The primary coaching intent for live guidance in this mode.
    func coachingObjective(for meetingType: String) -> String {
        switch meetingType {
        case "sales":
            return "Drive toward a concrete pilot or qualified next step. Keep answers outcome-focused and concise."
        case "demo":
            return "Showcase workflow value clearly. Guide toward the most impactful feature to demonstrate next."
        case "client-review":
            return "Reinforce progress, name the main open risk, and close on one accountable next action."
        case "interview":
            return "Answer directly, tie experience to the outcome they care about, and stay concise."
        case "internal-sync":
            return "Push toward a decision, a clear owner, and the next unblocking action."
        default:
            return "Keep answers direct, practical, and easy to act on."
        }
    }

    /// Key signal words to watch for in transcript for this mode.
    func successSignals(for meetingType: String) -> [String] {
        switch meetingType {
        case "sales":
            return ["pilot", "next step", "budget", "timeline", "rollout", "contract", "decision", "procurement"]
        case "demo":
            return ["workflow", "show", "integrate", "use case", "team", "onboard", "feature", "adoption"]
        case "client-review":
            return ["progress", "risk", "milestone", "deadline", "blocker", "status", "delivery", "scope"]
        case "interview":
            return ["experience", "example", "challenge", "result", "outcome", "role", "team", "culture"]
        case "internal-sync":
            return ["decision", "owner", "blocker", "alignment", "priority", "deadline", "shipped", "blocked"]
        default:
            return ["next step", "follow up", "action", "decision", "plan"]
        }
    }

    /// Tone direction for written follow-ups in this mode.
    func followUpToneInstruction(for meetingType: String) -> String {
        switch meetingType {
        case "sales":
            return "Keep it tight. One next step. No fluff. Match their energy."
        case "demo":
            return "Reference what resonated. Point clearly to the next workflow."
        case "client-review":
            return "Professional and accountable. Name the open risk and the owner."
        case "interview":
            return "Warm but concise. Reinforce fit with one strong signal."
        case "internal-sync":
            return "Internal tone. Skip pleasantries. Name decisions and owners."
        default:
            return "Friendly, direct, one clear ask at the end."
        }
    }

    /// System prompt section for live AI guidance builders (Ollama, OpenAI).
    /// Describes the mode objective and key signals to watch during the meeting.
    func systemPromptSection(for meetingType: String) -> String {
        let obj = coachingObjective(for: meetingType)
        let sigs = successSignals(for: meetingType).joined(separator: ", ")
        return """
        Mode (\(meetingType)): \(obj)
        Key signals to watch: \(sigs)
        """
    }

    /// Prompt section for AI-backed pre-meeting brief generation.
    /// Describes the mode goal, focus areas, likely risks, and available context flags.
    /// Use this when building a prompt that should produce a structured pre-meeting brief.
    func preMeetingPromptSection(
        for meetingType: String,
        hasDocs: Bool,
        hasPriorSession: Bool
    ) -> String {
        let obj = coachingObjective(for: meetingType)
        let areas = summaryFocusAreas(for: meetingType).prefix(3).joined(separator: ", ")
        let risks = preMeetingRisksLine(for: meetingType)

        var lines: [String] = [
            "Pre-meeting mode (\(meetingType)):",
            "Session goal: \(obj)",
            "Focus areas: \(areas)",
            "Likely risks: \(risks)",
        ]
        if hasDocs {
            lines.append("Attached documents available — surface specific relevant context from them.")
        }
        if hasPriorSession {
            lines.append("Prior session of this type exists — reference continuity context where relevant.")
        }
        return lines.joined(separator: "\n")
    }

    /// One-line risks summary used by `preMeetingPromptSection`.
    private func preMeetingRisksLine(for meetingType: String) -> String {
        switch meetingType {
        case "sales":
            return "budget gating, missing decision-maker, timeline misalignment"
        case "demo":
            return "workflow mismatch, integration objection, unprepared use case"
        case "client-review":
            return "invisible progress, undiscussed risk, scope drift"
        case "interview":
            return "unprepared example, narrower requirements, experience gap"
        case "internal-sync":
            return "stalled decision, unclear ownership, external dependencies"
        default:
            return "goal drift, decision not reached"
        }
    }

    /// Focus areas for post-meeting summaries in this mode.
    func summaryFocusAreas(for meetingType: String) -> [String] {
        switch meetingType {
        case "sales":
            return ["qualified next step", "budget signal", "timeline", "objection raised", "pilot scope"]
        case "demo":
            return ["workflow shown", "resonance signal", "next feature to demo", "onboarding fit"]
        case "client-review":
            return ["progress confirmed", "risk raised", "open action item", "trust signal"]
        case "interview":
            return ["question topic", "example cited", "fit signal", "follow-up ask"]
        case "internal-sync":
            return ["decision made", "owner named", "blocker identified", "next checkpoint"]
        default:
            return ["key topic", "decision", "next step", "open question"]
        }
    }

    // MARK: - Transcript signal extraction

    struct TranscriptSignals: Sendable {
        let hasBudgetMention: Bool
        let hasTimelineMention: Bool
        let hasPilotMention: Bool
        let hasFollowUpMention: Bool
        let hasCommitmentSignal: Bool
        let hasConcernSignal: Bool
        let hasSendRequest: Bool
        let hasPriceMention: Bool
        let hasDecisionSignal: Bool
        let hasBlockerSignal: Bool
        let hasQuestionSignal: Bool
        let hasOnboardingSignal: Bool
    }

    func extractSignals(from transcript: String) -> TranscriptSignals {
        let t = transcript.lowercased()
        return TranscriptSignals(
            hasBudgetMention:     t.contains("budget") || t.contains("cost") || t.contains("spend"),
            hasTimelineMention:   t.contains("timeline") || t.contains("next week") || t.contains("this week")
                                   || t.contains("by end of") || t.contains("deadline") || t.contains("by friday"),
            hasPilotMention:      t.contains("pilot") || t.contains("trial") || t.contains("proof of concept")
                                   || t.contains("poc") || t.contains("test run"),
            hasFollowUpMention:   t.contains("follow up") || t.contains("follow-up")
                                   || t.contains("circle back") || t.contains("reach out"),
            hasCommitmentSignal:  t.contains("we will") || t.contains("we'll") || t.contains("i will")
                                   || t.contains("i'll") || t.contains("let's") || t.contains("agreed"),
            hasConcernSignal:     t.contains("concern") || t.contains("worry") || t.contains("issue")
                                   || t.contains("problem") || t.contains("blocker") || t.contains("risk"),
            hasSendRequest:       t.contains("send") || t.contains("share") || t.contains("forward")
                                   || t.contains("email me"),
            hasPriceMention:      t.contains("price") || t.contains("pricing") || t.contains("rate")
                                   || t.contains("quote"),
            hasDecisionSignal:    t.contains("decided") || t.contains("decision") || t.contains("agreed")
                                   || t.contains("confirmed") || t.contains("approved"),
            hasBlockerSignal:     t.contains("blocker") || t.contains("blocked") || t.contains("waiting on")
                                   || t.contains("dependency") || t.contains("stuck"),
            hasQuestionSignal:    t.contains("question") || t.contains("asking") || t.contains("curious about")
                                   || t.contains("wondering"),
            hasOnboardingSignal:  t.contains("onboard") || t.contains("set up") || t.contains("get started")
                                   || t.contains("kick off")
        )
    }
}
