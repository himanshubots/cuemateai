import Foundation

struct DocumentChunker: Sendable {
    let chunkSize: Int
    let overlap: Int

    init(chunkSize: Int = 700, overlap: Int = 120) {
        self.chunkSize = chunkSize
        self.overlap = overlap
    }

    func makeChunks(documentID: UUID, text: String) -> [DocumentChunk] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return [] }

        var chunks: [DocumentChunk] = []
        var start = normalized.startIndex
        var index = 0

        while start < normalized.endIndex {
            let end = normalized.index(start, offsetBy: chunkSize, limitedBy: normalized.endIndex) ?? normalized.endIndex
            let slice = String(normalized[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)

            if !slice.isEmpty {
                chunks.append(
                    DocumentChunk(
                        id: UUID(),
                        documentID: documentID,
                        index: index,
                        text: slice
                    )
                )
                index += 1
            }

            guard end < normalized.endIndex else { break }
            start = normalized.index(end, offsetBy: -min(overlap, normalized.distance(from: start, to: end)), limitedBy: normalized.startIndex) ?? end
            if start == end { break }
        }

        return chunks
    }
}
