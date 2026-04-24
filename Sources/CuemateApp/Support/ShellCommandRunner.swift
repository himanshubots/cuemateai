import Foundation

enum ShellCommandError: LocalizedError {
    case launchFailed(String)
    case nonZeroExit(code: Int32, output: String)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let message):
            return message
        case .nonZeroExit(let code, let output):
            return "Command failed with exit code \(code): \(output)"
        }
    }
}

struct ShellCommandRunner: Sendable {
    func run(_ command: [String]) async throws -> String {
        guard let executable = command.first else {
            throw ShellCommandError.launchFailed("Missing executable")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let outputPipe = Pipe()
            let errorPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = Array(command.dropFirst())
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            process.environment = mergedEnvironment()

            process.terminationHandler = { process in
                let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data + errorData, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    continuation.resume(throwing: ShellCommandError.nonZeroExit(code: process.terminationStatus, output: output))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ShellCommandError.launchFailed(error.localizedDescription))
            }
        }
    }

    private func mergedEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let defaultPath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        let preferredSegments = ["/opt/homebrew/bin", "/usr/local/bin"]
        let existingSegments = defaultPath
            .split(separator: ":")
            .map(String.init)
        let mergedPath = (preferredSegments + existingSegments)
            .reduce(into: [String]()) { collected, segment in
                if !collected.contains(segment) {
                    collected.append(segment)
                }
            }
            .joined(separator: ":")
        environment["PATH"] = mergedPath
        return environment
    }
}
