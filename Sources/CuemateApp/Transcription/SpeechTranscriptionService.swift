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
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    var onTranscript: ((TranscriptSegment) -> Void)?

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

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        self.request = request

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let segment = TranscriptSegment(
                    id: UUID(),
                    speaker: "user",
                    text: result.bestTranscription.formattedString,
                    confidence: result.isFinal ? 0.95 : 0.7,
                    isFinal: result.isFinal,
                    createdAt: Date()
                )
                Task { @MainActor in
                    self.onTranscript?(segment)
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
    }
}
