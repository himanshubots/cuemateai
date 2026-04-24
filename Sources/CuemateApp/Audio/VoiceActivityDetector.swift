import Foundation

enum VoiceActivityState: String, Sendable {
    case silent
    case speaking
}

struct VoiceActivitySample: Sendable {
    let state: VoiceActivityState
    let level: Double
}

final class VoiceActivityDetector {
    private let speakingThreshold: Double
    private let hangoverFrames: Int
    private var trailingSilenceFrames = 0
    private var currentState: VoiceActivityState = .silent

    init(speakingThreshold: Double = 0.10, hangoverFrames: Int = 5) {
        self.speakingThreshold = speakingThreshold
        self.hangoverFrames = hangoverFrames
    }

    func process(level: Double) -> VoiceActivitySample {
        if level >= speakingThreshold {
            trailingSilenceFrames = 0
            currentState = .speaking
        } else {
            trailingSilenceFrames += 1
            if trailingSilenceFrames >= hangoverFrames {
                currentState = .silent
            }
        }

        return VoiceActivitySample(state: currentState, level: level)
    }
}
