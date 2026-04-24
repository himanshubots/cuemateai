import Foundation

struct DocumentStore: Sendable {
    let appPaths: AppPaths
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(appPaths: AppPaths) {
        self.appPaths = appPaths
    }

    private var libraryURL: URL {
        appPaths.indexesDirectory.appendingPathComponent("document-library.json")
    }

    func loadLibrary() throws -> DocumentLibrarySnapshot {
        guard FileManager.default.fileExists(atPath: libraryURL.path) else {
            return DocumentLibrarySnapshot(documents: [], chunks: [])
        }

        let configuredDecoder = JSONDecoder()
        configuredDecoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: libraryURL)
        return try configuredDecoder.decode(DocumentLibrarySnapshot.self, from: data)
    }

    func saveLibrary(_ snapshot: DocumentLibrarySnapshot) throws {
        let configuredEncoder = JSONEncoder()
        configuredEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        configuredEncoder.dateEncodingStrategy = .iso8601
        let data = try configuredEncoder.encode(snapshot)
        try data.write(to: libraryURL, options: [.atomic])
    }

    func copyDocument(from sourceURL: URL, documentID: UUID) throws -> URL {
        let destination = appPaths.documentsDirectory
            .appendingPathComponent(documentID.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        let target = destination.appendingPathComponent(sourceURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
        }
        try FileManager.default.copyItem(at: sourceURL, to: target)
        return target
    }
}
