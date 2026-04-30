import AVFoundation
import Foundation
import Speech

enum SpeechPermissionState: String, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@MainActor
final class SpeechTranscriptionService {
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var lastCommittedTranscript = ""
    var onTranscript: ((TranscriptSegment) -> Void)?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        recognizer?.defaultTaskHint = .dictation
    }

    /// Swaps the locale before the next `start()` call.
    func setLocale(_ locale: Locale) {
        let newRecognizer = SFSpeechRecognizer(locale: locale)
        recognizer = newRecognizer ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        recognizer?.defaultTaskHint = .dictation
    }

    func requestPermission() async -> SpeechPermissionState {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    let mapped: SpeechPermissionState
                    switch status {
                    case .authorized: mapped = .authorized
                    case .denied: mapped = .denied
                    case .restricted: mapped = .restricted
                    case .notDetermined: mapped = .notDetermined
                    @unknown default: mapped = .denied
                    }
                    continuation.resume(returning: mapped)
                }
            }
        @unknown default:
            return .denied
        }
    }

    func start() {
        stop()

        guard let recognizer, recognizer.isAvailable else {
            return
        }

        recognizer.defaultTaskHint = .dictation

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.requiresOnDeviceRecognition = recognizer.supportsOnDeviceRecognition
        request.addsPunctuation = true
        self.request = request

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                guard let fullTranscriptText = TranscriptSanitizer.normalizedText(result.bestTranscription.formattedString) else {
                    return
                }
                let incrementalText = self.incrementalTranscriptText(from: fullTranscriptText)
                guard let transcriptText = TranscriptSanitizer.normalizedText(incrementalText) else {
                    if result.isFinal {
                        self.lastCommittedTranscript = fullTranscriptText
                    }
                    return
                }
                let segment = TranscriptSegment(
                    id: UUID(),
                    speaker: "user",
                    text: transcriptText,
                    confidence: result.isFinal ? 0.95 : 0.7,
                    isFinal: result.isFinal,
                    createdAt: Date()
                )
                Task { @MainActor in
                    self.onTranscript?(segment)
                }

                if result.isFinal {
                    self.lastCommittedTranscript = fullTranscriptText
                }
            }

            if error != nil {
                Task { @MainActor in
                    self.stop()
                }
            }
        }
    }

    func append(buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }

    func stop() {
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        lastCommittedTranscript = ""
    }

    private func incrementalTranscriptText(from fullText: String) -> String {
        let committedWords = words(in: lastCommittedTranscript)
        let fullWords = words(in: fullText)

        guard !committedWords.isEmpty, fullWords.count >= committedWords.count else {
            return fullText
        }

        var prefixCount = 0
        for (committed, current) in zip(committedWords, fullWords) {
            if committed.caseInsensitiveCompare(current) == .orderedSame {
                prefixCount += 1
            } else {
                break
            }
        }

        let suffixWords = fullWords.dropFirst(prefixCount)
        return suffixWords.isEmpty ? "" : suffixWords.joined(separator: " ")
    }

    private func words(in text: String) -> [String] {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
}
