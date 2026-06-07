import Foundation

struct GenerationOptions: Sendable {
    var maxTokens: Int
    var temperature: Double

    nonisolated init(maxTokens: Int = 512, temperature: Double = 0.7) {
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}
