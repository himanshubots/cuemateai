import Foundation

struct RetrievalSearchResult: Identifiable, Sendable {
    let id: UUID
    let document: IngestedDocument
    let chunk: DocumentChunk
    let score: Double
    let matchedTerms: [String]
}

struct RetrievalSearchResponse: Sendable {
    let results: [RetrievalSearchResult]
    let modeLabel: String
    let indexedChunkCount: Int
}

final class RetrievalEngine: Sendable {
    private let documentStore: DocumentStore
    private let embeddingStore: EmbeddingStore
    private let embeddingProvider: HashedEmbeddingProvider

    init(
        appPaths: AppPaths,
        documentStore: DocumentStore? = nil,
        embeddingStore: EmbeddingStore? = nil,
        embeddingProvider: HashedEmbeddingProvider = HashedEmbeddingProvider()
    ) {
        self.documentStore = documentStore ?? DocumentStore(appPaths: appPaths)
        self.embeddingStore = embeddingStore ?? EmbeddingStore(appPaths: appPaths)
        self.embeddingProvider = embeddingProvider
    }

    func search(query: String, topK: Int = 5) throws -> RetrievalSearchResponse {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return RetrievalSearchResponse(results: [], modeLabel: "Idle", indexedChunkCount: 0)
        }

        let library = try documentStore.loadLibrary()
        let queryVector = embeddingProvider.embed(trimmed)
        let queryTokens = Set(embeddingProvider.tokenize(trimmed))
        let embeddings = try ensureEmbeddings(for: library.chunks)
        let documentMap = Dictionary(uniqueKeysWithValues: library.documents.map { ($0.id, $0) })

        let ranked = library.chunks.compactMap { chunk -> RetrievalSearchResult? in
            guard let vector = embeddings[chunk.id], let document = documentMap[chunk.documentID] else {
                return nil
            }

            let chunkTokens = Set(embeddingProvider.tokenize(chunk.text))
            let overlap = queryTokens.intersection(chunkTokens)
            let lexicalBonus = Double(overlap.count) * 0.08
            let similarity = cosineSimilarity(queryVector, vector)
            let totalScore = similarity + lexicalBonus

            guard totalScore > 0.01 else { return nil }

            return RetrievalSearchResult(
                id: chunk.id,
                document: document,
                chunk: chunk,
                score: totalScore,
                matchedTerms: Array(overlap).sorted()
            )
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.chunk.index < rhs.chunk.index
            }
            return lhs.score > rhs.score
        }

        return RetrievalSearchResponse(
            results: Array(ranked.prefix(topK)),
            modeLabel: "Local hashed embeddings",
            indexedChunkCount: embeddings.count
        )
    }

    private func ensureEmbeddings(for chunks: [DocumentChunk]) throws -> [UUID: [Double]] {
        var cache = try embeddingStore.load()
        var map = Dictionary(uniqueKeysWithValues: cache.records.map { ($0.chunkID, $0.vector) })
        var changed = false

        for chunk in chunks where map[chunk.id] == nil {
            let vector = embeddingProvider.embed(chunk.text)
            let record = ChunkEmbeddingRecord(
                chunkID: chunk.id,
                documentID: chunk.documentID,
                model: embeddingProvider.modelName,
                vector: vector
            )
            cache.records.append(record)
            map[chunk.id] = vector
            changed = true
        }

        if changed {
            try embeddingStore.save(cache)
        }

        return map
    }

    private func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double {
        guard lhs.count == rhs.count else { return 0 }
        return zip(lhs, rhs).reduce(0) { $0 + ($1.0 * $1.1) }
    }
}
