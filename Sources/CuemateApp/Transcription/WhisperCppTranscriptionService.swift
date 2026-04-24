import AVFoundation
import Foundation

enum WhisperCppRuntimeState: Sendable, Equatable {
    case ready(executable: String, modelPath: String)
    case missingExecutable
    case missingModel
}

@MainActor
final class WhisperCppTranscriptionService {
    private let appPaths: AppPaths
    private let shell: ShellCommandRunner
    private var bufferedSamples: [Float] = []
    private var sampleRate = 16_000.0
    private var isRunning = false
    private var isTranscribing = false
    private var chunkIndex = 0

    var onTranscript: ((TranscriptSegment) -> Void)?

    init(appPaths: AppPaths, shell: ShellCommandRunner = ShellCommandRunner()) {
        self.appPaths = appPaths
        self.shell = shell
    }

    func runtimeState() async -> WhisperCppRuntimeState {
        if let executable = await findExecutable() {
            if let modelPath = findModelPath() {
                return .ready(executable: executable, modelPath: modelPath)
            }
            return .missingModel
        }
        return .missingExecutable
    }

    func start() {
        bufferedSamples.removeAll(keepingCapacity: true)
        chunkIndex = 0
        isRunning = true
    }

    func append(buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        guard isRunning else { return }

        sampleRate = format.sampleRate
        guard let channelData = buffer.floatChannelData else { return }
        let channel = channelData[0]
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        bufferedSamples.append(contentsOf: UnsafeBufferPointer(start: channel, count: frameLength))

        let minimumChunkFrameCount = Int(sampleRate * 3.0)
        guard bufferedSamples.count >= minimumChunkFrameCount, !isTranscribing else { return }

        let chunkSamples = bufferedSamples
        bufferedSamples.removeAll(keepingCapacity: true)
        chunkIndex += 1
        isTranscribing = true

        Task {
            await transcribeChunk(samples: chunkSamples, sampleRate: sampleRate, index: chunkIndex)
            await MainActor.run {
                self.isTranscribing = false
            }
        }
    }

    func stop() {
        isRunning = false
        bufferedSamples.removeAll()
    }

    private func transcribeChunk(samples: [Float], sampleRate: Double, index: Int) async {
        let runtime = await runtimeState()
        guard case let .ready(executable, modelPath) = runtime else {
            return
        }

        let chunkDirectory = appPaths.logsDirectory.appendingPathComponent("whisper-chunks", isDirectory: true)
        let audioURL = chunkDirectory.appendingPathComponent("chunk-\(index).wav")
        let outputBaseURL = chunkDirectory.appendingPathComponent("chunk-\(index)")
        let textURL = outputBaseURL.appendingPathExtension("txt")

        do {
            try FileManager.default.createDirectory(at: chunkDirectory, withIntermediateDirectories: true)
            try writeWAV(samples: samples, sampleRate: sampleRate, to: audioURL)

            _ = try await shell.run([
                executable,
                "-m", modelPath,
                "-f", audioURL.path,
                "-l", "en",
                "-otxt",
                "-of", outputBaseURL.path
            ])

            let transcript = try String(contentsOf: textURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !transcript.isEmpty else { return }

            await MainActor.run {
                self.onTranscript?(
                    TranscriptSegment(
                        id: UUID(),
                        speaker: "user",
                        text: transcript,
                        confidence: 0.76,
                        isFinal: true,
                        createdAt: Date()
                    )
                )
            }
        } catch {
            // Silent fallback keeps the app usable even when the local runtime is half-configured.
        }
    }

    private func findExecutable() async -> String? {
        let candidates = [
            "/opt/homebrew/bin/whisper-cli",
            "/usr/local/bin/whisper-cli",
            appPaths.modelsDirectory.appendingPathComponent("whisper/bin/whisper-cli").path,
            appPaths.modelsDirectory.appendingPathComponent("whisper.cpp/build/bin/whisper-cli").path,
            appPaths.modelsDirectory.appendingPathComponent("whisper.cpp/main").path
        ]

        if let local = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return local
        }

        if let whichResult = try? await shell.run(["/usr/bin/which", "whisper-cli"]), !whichResult.isEmpty {
            return whichResult
        }

        if let whichResult = try? await shell.run(["/usr/bin/which", "main"]), !whichResult.isEmpty {
            return whichResult
        }

        return nil
    }

    private func findModelPath() -> String? {
        let bundledDirectory = appPaths.modelsDirectory.appendingPathComponent("whisper", isDirectory: true)
        let explicitCandidates = [
            bundledDirectory.appendingPathComponent("ggml-base.en.bin").path,
            bundledDirectory.appendingPathComponent("ggml-base.bin").path
        ]

        for candidate in explicitCandidates where FileManager.default.fileExists(atPath: candidate) {
            return candidate
        }

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: bundledDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return nil
        }

        return files.first(where: { $0.lastPathComponent.hasPrefix("ggml-") && $0.pathExtension == "bin" })?.path
    }

    private func writeWAV(samples: [Float], sampleRate: Double, to url: URL) throws {
        var data = Data()
        let byteRate = UInt32(sampleRate) * 2
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16

        let pcmData = Data(samples.flatMap { sample -> [UInt8] in
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Float(Int16.max))
            let littleEndian = intSample.littleEndian
            return withUnsafeBytes(of: littleEndian) { Array($0) }
        })

        data.append("RIFF".data(using: .ascii)!)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(36 + pcmData.count).littleEndian, Array.init))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian, Array.init))
        data.append("data".data(using: .ascii)!)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(pcmData.count).littleEndian, Array.init))
        data.append(pcmData)

        try data.write(to: url, options: [.atomic])
    }
}
