import Foundation

struct IngestedDocument: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let fileName: String
    let fileType: String
    let sourcePath: String
    let importedAt: Date
    let chunkCount: Int
    let characterCount: Int
}

struct DocumentChunk: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    let documentID: UUID
    let index: Int
    let text: String
}

struct DocumentLibrarySnapshot: Codable, Sendable {
    var documents: [IngestedDocument]
    var chunks: [DocumentChunk]
}
