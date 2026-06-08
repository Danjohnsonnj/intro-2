import Foundation

enum AugmentationTrigger: Sendable {
    case send
}

protocol ContextAugmentation: Sendable {
    func augment(
        messages: [ChatPromptMessage],
        trigger: AugmentationTrigger
    ) async throws -> [ChatPromptMessage]
}

struct NoOpContextAugmentation: ContextAugmentation {
    func augment(
        messages: [ChatPromptMessage],
        trigger: AugmentationTrigger
    ) async throws -> [ChatPromptMessage] {
        _ = trigger
        return messages
    }
}
