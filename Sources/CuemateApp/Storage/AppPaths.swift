import Foundation

struct AppPaths: Equatable, Sendable {
    let baseDirectory: URL
    let modelsDirectory: URL
    let documentsDirectory: URL
    let embeddingsDirectory: URL
    let logsDirectory: URL
    let configDirectory: URL
    let indexesDirectory: URL
    let sessionsDirectory: URL

    static var `default`: AppPaths {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/cuemate", isDirectory: true)

        return AppPaths(
            baseDirectory: base,
            modelsDirectory: base.appendingPathComponent("models", isDirectory: true),
            documentsDirectory: base.appendingPathComponent("documents", isDirectory: true),
            embeddingsDirectory: base.appendingPathComponent("embeddings", isDirectory: true),
            logsDirectory: base.appendingPathComponent("logs", isDirectory: true),
            configDirectory: base.appendingPathComponent("config", isDirectory: true),
            indexesDirectory: base.appendingPathComponent("indexes", isDirectory: true),
            sessionsDirectory: base.appendingPathComponent("sessions", isDirectory: true)
        )
    }

    func prepareDirectories() throws {
        let fileManager = FileManager.default
        let directories = [
            baseDirectory,
            modelsDirectory,
            documentsDirectory,
            embeddingsDirectory,
            logsDirectory,
            configDirectory,
            indexesDirectory,
            sessionsDirectory
        ]

        for directory in directories {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}
