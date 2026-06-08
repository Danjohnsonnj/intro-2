import Foundation

nonisolated protocol LlamaCppBridge: Sendable {
    func loadModel(path: String) throws
    func unloadModel()
    func countTemplatedUserPromptTokens(_ user: String) throws -> Int
    func countChatPromptTokens(messages: [ChatPromptMessage], addGenerationPrompt: Bool) throws -> Int
    func maxTemplatedPromptTokensForGeneration(_ generationMaxTokens: Int) -> Int
    func formatChatPrompt(messages: [ChatPromptMessage], addGenerationPrompt: Bool) throws -> String
    func startTemplatedUserPrompt(_ user: String, options: GenerationOptions) throws
    func startRawPrompt(_ fullChatPrompt: String, options: GenerationOptions) throws
    func nextTokenChunk() throws -> String?
    func cancelGeneration()
}
