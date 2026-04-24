import Foundation

enum DependencyValidation: Equatable {
    case command(String)
    case file(relativePath: String)
    case ollamaModel(String)
}

struct DependencyInstallPlan: Equatable {
    let description: String
    let commands: [[String]]
}

struct DependencyInstallStep: Sendable {
    let index: Int
    let total: Int
    let commandSummary: String
}

struct DependencyInspectionResult: Equatable {
    let descriptor: DependencyDescriptor
    let status: DependencyStatus
    let detail: String
}

final class DependencyInstaller: Sendable {
    private let appPaths: AppPaths
    private let shell: ShellCommandRunner

    init(appPaths: AppPaths, shell: ShellCommandRunner = ShellCommandRunner()) {
        self.appPaths = appPaths
        self.shell = shell
    }

    func inspectAll(descriptors: [DependencyDescriptor]) async -> [DependencyInspectionResult] {
        var results: [DependencyInspectionResult] = []

        for descriptor in descriptors {
            let result = await inspect(descriptor: descriptor)
            results.append(result)
        }

        return results
    }

    func inspect(descriptor: DependencyDescriptor) async -> DependencyInspectionResult {
        switch descriptor.validation {
        case .command(let name):
            if let executable = await findExecutable(named: name) {
                return DependencyInspectionResult(
                    descriptor: descriptor,
                    status: .ready,
                    detail: "Found at \(executable)"
                )
            }

            return DependencyInspectionResult(
                descriptor: descriptor,
                status: .missing,
                detail: "Command \(name) is not available yet"
            )

        case .file(let relativePath):
            let target = appPaths.baseDirectory.appendingPathComponent(relativePath)
            let exists = FileManager.default.fileExists(atPath: target.path)

            return DependencyInspectionResult(
                descriptor: descriptor,
                status: exists ? .ready : .missing,
                detail: exists ? "Bundle is present at \(target.path)" : "Expected bundle at \(target.path)"
            )

        case .ollamaModel(let modelName):
            guard await findExecutable(named: "ollama") != nil else {
                return DependencyInspectionResult(
                    descriptor: descriptor,
                    status: .missing,
                    detail: "Ollama is not installed yet"
                )
            }

            do {
                let output = try await shell.run(["/bin/zsh", "-lc", "ollama list"])
                let isInstalled = output
                    .split(separator: "\n")
                    .contains { line in
                        line.split(whereSeparator: \.isWhitespace).first.map(String.init) == modelName
                    }

                return DependencyInspectionResult(
                    descriptor: descriptor,
                    status: isInstalled ? .ready : .missing,
                    detail: isInstalled ? "\(modelName) is installed" : "\(modelName) has not been pulled yet"
                )
            } catch {
                return DependencyInspectionResult(
                    descriptor: descriptor,
                    status: .failed,
                    detail: "Ollama is installed, but the runtime check failed. Open Ollama and re-run the check."
                )
            }
        }
    }

    func execute(
        plan: DependencyInstallPlan,
        onStep: (@Sendable (DependencyInstallStep) async -> Void)? = nil
    ) async -> Result<Void, Error> {
        do {
            for (index, command) in plan.commands.enumerated() {
                if let onStep {
                    await onStep(
                        DependencyInstallStep(
                            index: index + 1,
                            total: plan.commands.count,
                            commandSummary: summarize(command: command)
                        )
                    )
                }
                _ = try await shell.run(command)
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func findExecutable(named name: String) async -> String? {
        let bundledCandidates = candidatePaths(for: name)

        if let directHit = bundledCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            return directHit
        }

        if let path = try? await shell.run(["/usr/bin/which", name]), !path.isEmpty {
            return path
        }

        return nil
    }

    private func candidatePaths(for name: String) -> [String] {
        switch name {
        case "ollama":
            return [
                "/opt/homebrew/bin/ollama",
                "/usr/local/bin/ollama",
                "/Applications/Ollama.app/Contents/Resources/ollama"
            ]
        case "whisper-cli":
            return [
                "/opt/homebrew/bin/whisper-cli",
                "/usr/local/bin/whisper-cli"
            ]
        case "brew":
            return [
                "/opt/homebrew/bin/brew",
                "/usr/local/bin/brew"
            ]
        default:
            return [
                "/opt/homebrew/bin/\(name)",
                "/usr/local/bin/\(name)"
            ]
        }
    }

    private func summarize(command: [String]) -> String {
        command.joined(separator: " ")
    }
}
