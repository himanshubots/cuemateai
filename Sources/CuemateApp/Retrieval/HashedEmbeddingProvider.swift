import Foundation

struct HashedEmbeddingProvider: Sendable {
    let dimensions: Int
    let modelName: String

    init(dimensions: Int = 256, modelName: String = "local-hash-v1") {
        self.dimensions = dimensions
        self.modelName = modelName
    }

    func embed(_ text: String) -> [Double] {
        let tokens = tokenize(text)
        guard !tokens.isEmpty else { return Array(repeating: 0, count: dimensions) }

        var vector = Array(repeating: 0.0, count: dimensions)

        for token in tokens {
            let index = abs(token.hashValue) % dimensions
            vector[index] += 1.0
        }

        let magnitude = sqrt(vector.reduce(0) { $0 + ($1 * $1) })
        guard magnitude > 0 else { return vector }

        return vector.map { $0 / magnitude }
    }

    func tokenize(_ text: String) -> [String] {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
    }
}
