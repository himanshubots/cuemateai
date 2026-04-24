import Foundation

struct PerformanceSample: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let durationMs: Double
    let budgetMs: Double
    let timestamp: Date

    var withinBudget: Bool {
        durationMs <= budgetMs
    }
}

struct PerformanceSummary: Sendable {
    var samples: [PerformanceSample] = []

    mutating func record(name: String, durationMs: Double, budgetMs: Double) {
        samples.insert(
            PerformanceSample(
                name: name,
                durationMs: durationMs,
                budgetMs: budgetMs,
                timestamp: Date()
            ),
            at: 0
        )

        if samples.count > 20 {
            samples = Array(samples.prefix(20))
        }
    }

    func latest(named name: String) -> PerformanceSample? {
        samples.first(where: { $0.name == name })
    }
}

enum PerformanceBudget {
    static let transcriptionUpdateMs = 500.0
    static let responseGenerationMs = 1500.0
    static let retrievalMs = 300.0
    static let uiRefreshMs = 100.0
}
