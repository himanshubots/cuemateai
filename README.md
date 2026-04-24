# Cuemate

Cuemate is a local-first, agentic meeting assistant for macOS designed to help you recover context, think faster, answer better, and act clearly in live conversations.

It sits near your camera, listens locally, turns questions into guidance, and helps you stay in flow during:
- sales calls
- demos
- internal meetings
- technical discussions
- client presentations

## Why Cuemate

You are in a meeting, your name comes up, and suddenly you realize you missed the last part of the conversation.

You go blank.
You say, "Sorry, I missed that."
And honestly, that happens to all of us.

When you are juggling multiple meetings, tasks, and context switches, it is normal to miss things.
Staying fully present all the time is hard.

Most meeting software is built for recording, summarizing, and reviewing after the moment is already gone.

Cuemate is built for the live moment.

It helps you:
- recover the thread when you miss context
- hear the question
- understand what is happening faster
- generate a strong answer fast
- keep a next action ready
- avoid losing momentum while speaking
- stay organized while the conversation keeps moving

## Core Product Format

Cuemate is centered around two simple flows:

### Quick Start

1. Install runtime and local models
2. Test microphone, transcript, and overlay placement
3. Start a session and go live

### Question / Answer / Action

- Question: what was just asked
- Answer: what you should say now
- Action: the best next move to keep the conversation progressing

## What Cuemate Does Today

- Native macOS app built with SwiftUI and AppKit
- System-level assistant experience for live conversations
- Floating guidance overlay for in-the-moment help
- Live microphone capture and transcript pipeline
- Apple Speech and `whisper.cpp` transcription paths
- Local heuristic guidance with Ollama and OpenAI options
- Streaming response preview for lower-latency answer generation
- Setup flow for runtime install, testing, and live usage
- Meeting sessions with saved transcript and guidance history
- Review flow with summaries and follow-up notes
- Local-first configuration and document storage

## Product Vision

Cuemate is being shaped into an open-source, privacy-first, agentic assistant for serious live work.

The long-term vision includes:
- an agentic meeting assistant that reasons over live context, notes, and documents
- multilingual listening and response workflows
- stronger offline and local-only operation
- safer data boundaries and user-controlled model routing
- autonomous background behavior for small useful tasks
- richer memory across sessions
- better cross-call preparation and follow-up actions
- a more polished, production-ready open-source macOS app

## Capabilities Roadmap

### Available

- Local-first macOS architecture
- Camera-adjacent overlay
- STT testing and setup flow
- Transcript-driven answer generation
- Session history and review
- Ollama streaming guidance
- Document-backed context retrieval

### Upcoming

- Agentic AI workflows:
  Background context gathering, next-step planning, and more proactive meeting assistance.

- Multilingual support:
  Listen and assist across more languages with better language switching and multilingual sessions.

- Offline data safety:
  Stronger local-only workflows, clearer storage controls, and safer boundaries for sensitive conversations.

- Open-source contributor mode:
  Better docs, easier local setup, and a cleaner public repo experience.

- Autonomous background help:
  A more agentic assistant that can run quietly in the background and handle small tasks when asked.

- Speaker-aware meeting intelligence:
  Better participant labeling and eventually stronger attribution strategies.

- Vision-aware workflows:
  Smarter screen-context understanding and meeting-context awareness where platform capabilities allow.

- Faster live answer generation:
  More aggressive low-latency streaming and better interruption handling.

- Meeting memory:
  Reusable context across sessions so Cuemate gets more useful over time.

## Screens and UX

Cuemate is organized around a few clear surfaces:
- Setup: install, test, and get ready fast
- Live: run one real meeting workflow
- Review: revisit sessions, summaries, and actions
- Overlay: keep live guidance close when you need help staying on track

## Tech Stack

- Swift Package Manager
- SwiftUI
- AppKit
- AVFoundation
- Speech
- Local file-based storage
- Ollama
- OpenAI API optional fallback

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

This repository is being prepared to feel more like a real open-source product and less like an internal prototype.

That means the public surface should focus on:
- product clarity
- local-first architecture
- real meeting pain points
- macOS polish
- privacy and safety boundaries
- contributor friendliness
- practical live-use workflows

## Contributing

Issues, ideas, UX feedback, and pull requests are welcome.

Good contributions include:
- making the live flow simpler
- reducing latency
- improving macOS polish
- improving privacy and local-first behavior
- improving real-time context recovery
- making setup easier for contributors

## License

Add your preferred open-source license here before publishing.
