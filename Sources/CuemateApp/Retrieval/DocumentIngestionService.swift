import Foundation
import PDFKit

enum DocumentIngestionError: LocalizedError {
    case unsupportedFileType(String)
    case unreadableDocument(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .unreadableDocument(let path):
            return "Could not read document at \(path)"
        }
    }
}

struct DocumentIngestionResult: Sendable {
    let document: IngestedDocument
    let chunks: [DocumentChunk]
}

final class DocumentIngestionService: Sendable {
    private let appPaths: AppPaths
    private let chunker: DocumentChunker
    private let store: DocumentStore

    init(appPaths: AppPaths, chunker: DocumentChunker = DocumentChunker(), store: DocumentStore? = nil) {
        self.appPaths = appPaths
        self.chunker = chunker
        self.store = store ?? DocumentStore(appPaths: appPaths)
    }

    func loadExistingLibrary() throws -> DocumentLibrarySnapshot {
        try store.loadLibrary()
    }

    func ingest(url: URL) throws -> DocumentIngestionResult {
        let fileType = url.pathExtension.lowercased()
        let text = try extractText(from: url, fileType: fileType)
        let documentID = UUID()
        let chunks = chunker.makeChunks(documentID: documentID, text: text)
        let copiedURL = try store.copyDocument(from: url, documentID: documentID)

        var snapshot = try store.loadLibrary()
        let document = IngestedDocument(
            id: documentID,
            fileName: url.lastPathComponent,
            fileType: fileType,
            sourcePath: copiedURL.path,
            importedAt: Date(),
            chunkCount: chunks.count,
            characterCount: text.count
        )

        snapshot.documents.append(document)
        snapshot.chunks.append(contentsOf: chunks)
        try store.saveLibrary(snapshot)

        return DocumentIngestionResult(document: document, chunks: chunks)
    }

    private func extractText(from url: URL, fileType: String) throws -> String {
        switch fileType {
        case "txt", "md":
            return try String(contentsOf: url, encoding: .utf8)
        case "pdf":
            guard let document = PDFDocument(url: url), let text = document.string, !text.isEmpty else {
                throw DocumentIngestionError.unreadableDocument(url.path)
            }
            return text
        default:
            throw DocumentIngestionError.unsupportedFileType(fileType)
        }
    }
}
