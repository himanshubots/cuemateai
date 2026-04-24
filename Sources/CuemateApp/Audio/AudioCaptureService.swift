import AVFoundation
import Foundation

struct AudioFrameSample: Sendable {
    let level: Double
    let frameCount: Int
    let sampleRate: Double
}

enum AudioCaptureState: String, Sendable {
    case idle
    case requestingPermission
    case ready
    case capturing
    case denied
    case failed
}

final class AudioCaptureService: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var frameCounter = 0
    var onFrame: (@MainActor @Sendable (AudioFrameSample) -> Void)?
    var onAudioBuffer: ((AVAudioPCMBuffer, AVAudioFormat) -> Void)?

    func requestPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func start() throws {
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        frameCounter = 0

        inputNode.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self else { return }

            let level = Self.rmsLevel(from: buffer)
            self.frameCounter += 1
            let sample = AudioFrameSample(
                level: level,
                frameCount: self.frameCounter,
                sampleRate: format.sampleRate
            )

            let onFrame = self.onFrame
            let onAudioBuffer = self.onAudioBuffer

            Task { @MainActor in
                onFrame?(sample)
            }

            onAudioBuffer?(buffer, format)
        }

        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
    }

    private static func rmsLevel(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channel = channelData[0]
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }

        var sum = 0.0
        for index in 0..<frameLength {
            let sample = Double(channel[index])
            sum += sample * sample
        }

        let rms = sqrt(sum / Double(frameLength))
        return min(max(rms, 0), 1)
    }
}
