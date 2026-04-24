import Foundation

struct ChunkEmbeddingRecord: Codable, Sendable {
    let chunkID: UUID
    let documentID: UUID
    let model: String
    let vector: [Double]
}

struct EmbeddingCacheSnapshot: Codable, Sendable {
    var records: [ChunkEmbeddingRecord]
}

struct EmbeddingStore: Sendable {
    let appPaths: AppPaths
    private let decoder = JSONDecoder()

    init(appPaths: AppPaths) {
        self.appPaths = appPaths
    }

    private var cacheURL: URL {
        appPaths.embeddingsDirectory.appendingPathComponent("chunk-embeddings.json")
    }

    func load() throws -> EmbeddingCacheSnapshot {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return EmbeddingCacheSnapshot(records: [])
        }

        let data = try Data(contentsOf: cacheURL)
        return try decoder.decode(EmbeddingCacheSnapshot.self, from: data)
    }

    func save(_ snapshot: EmbeddingCacheSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: cacheURL, options: [.atomic])
    }
}
