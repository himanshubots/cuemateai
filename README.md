# Cuemate

Cuemate is a local-first meeting copilot for macOS. It listens to live conversations, helps you recover context and structure answers in the moment, and gives you a practical brief before the meeting starts — all without sending your audio or transcripts anywhere you did not choose.

It works across:
- sales calls
- demos
- client reviews
- interviews
- internal syncs

## Why Cuemate

You are in a meeting, your name comes up, and you realize you missed the last part of the conversation.

You go blank.

Most meeting software is built for recording and summarizing after the moment is already gone. Cuemate is built for the live moment — and for the prep before it and the follow-up after it.

It helps you:
- arrive prepared with a clear goal, focus areas, and opening framing
- recover the thread quickly when you miss context
- structure a response and identify the next move
- leave every session with a summary, action items, and a draft follow-up

## Three Surfaces

### Start Session

Pick a meeting type, attach any relevant documents, and start. Cuemate generates a pre-meeting brief covering your goal, focus areas, likely risks, and how to open the meeting. When you are ready, the live guidance overlay activates.

The live overlay gives you:
- the question that was just asked
- a structured answer
- a suggested next action

### History

Every completed session leaves behind a full record: overview, key topics, action items, decision summary, follow-up draft, and the pre-meeting brief that was used. History is local — nothing is sent to a server.

### Settings

Configure your transcription path (Apple Speech or `whisper.cpp`), your AI provider (local heuristic, Ollama, or OpenAI), your speaker identity, your preferred answer style (balanced / safe / assertive / consultative), and your OpenAI API key (stored in Keychain).

## What Cuemate Does Today

- Native macOS app built with SwiftUI and AppKit
- Floating guidance overlay for in-the-moment help
- Live microphone capture with Apple Speech and `whisper.cpp` paths
- Meeting mode templates: sales call, demo, client review, interview, internal sync, general
- Pre-meeting briefs: goal, focus areas, likely risks, opening framing, document highlights, prior session note
- AI brief enrichment via Ollama (local) or OpenAI (optional)
- Live guidance with intent detection, objection/decision playbooks, and interruption recovery
- Signal-based confidence scoring that shapes live answer behavior
- Mode focus and risk cues in the live coaching card for all six meeting types
- Preferred answer style: bias live guidance toward balanced, safe, assertive, or consultative
- Recurring session memory: start-session workspace surfaces recent outcome, themes, and decision patterns from prior sessions of the same type
- Post-meeting summaries: overview, key topics, action items, decision summary, outcome note
- Follow-up draft generation with subject line
- Session history browser with all artifacts persisted locally
- Document-backed context retrieval for grounded guidance
- OpenAI key stored in macOS Keychain — never in plaintext config
- Privacy/transparency panel in Settings showing exactly what stays local

## Privacy Model

- Transcription runs on-device via Apple Speech or `whisper.cpp` by default
- Documents, session records, transcripts, and configuration are stored locally in App Support
- OpenAI is only contacted when you explicitly configure an API key and select that provider
- Ollama runs locally — no external network calls
- Nothing is sent to Cuemate servers (there are none)

## Capabilities Roadmap

### Available

- Local-first macOS architecture
- Live overlay with answer and action guidance
- Meeting mode templates and pre-meeting briefs
- Post-meeting summaries and follow-up drafts
- Session history with persisted artifacts
- Ollama and OpenAI brief generation with heuristic fallback
- Document-backed retrieval context
- Signal-based live intelligence and playbook guidance
- Mode-specific focus and risk cues in the live coaching layer
- Preferred answer style setting (balanced / safe / assertive / consultative)
- Lightweight recurring session memory at session start
- Privacy transparency in Settings

### Upcoming

- Agentic AI workflows: background context gathering, next-step planning, proactive assistance
- Multilingual support: listen and assist across more languages
- Deeper cross-session memory and personalization: richer reuse of past decisions and patterns
- Stronger offline safety: clearer storage controls and local-only defaults
- Open-source contributor mode: easier local setup and a cleaner public repo experience

## Tech Stack

- Swift Package Manager
- SwiftUI + AppKit
- AVFoundation + Speech
- Local file-based storage (App Support)
- Ollama (local inference)
- OpenAI API (optional, key in Keychain)

## Run Locally

### Requirements

- macOS 14+
- Apple Silicon recommended
- Xcode or Command Line Tools

### Build

```bash
swift build
```

### Run

```bash
swift run cuemate
```

### Build the macOS app bundle

```bash
./scripts/build_macos_app.sh
```

The app bundle will be created at:

```text
dist/Cuemate.app
```

## Open Source Direction

This repository is being shaped into a clean, privacy-first open-source product. The public surface prioritizes:
- product clarity and honest capability claims
- local-first architecture and user-controlled data
- real meeting pain points
- macOS polish
- contributor friendliness

## Contributing

Issues, ideas, UX feedback, and pull requests are welcome.

Good contributions:
- simplifying the live flow
- reducing latency
- improving macOS polish
- improving privacy and local-first behavior
- improving real-time context recovery
- making setup easier for contributors

## License

Add your preferred open-source license here before publishing.
