import Foundation

#if canImport(llama)
import llama
#endif

struct ChatPromptMessage: Sendable, Equatable {
    let role: String
    let content: String

    nonisolated static let roleUser = "user"
    nonisolated static let roleAssistant = "assistant"
    nonisolated static let roleSystem = "system"
}

enum ChatPromptBuilder {
    nonisolated static let defaultSystemPrompt =
        "You are a helpful assistant. Give complete but concise responses. "
        + "Prefer short paragraphs and avoid unnecessary preamble."

    nonisolated static func transcript(
        systemPrompt: String = defaultSystemPrompt,
        history: [ChatPromptMessage]
    ) -> [ChatPromptMessage] {
        var messages: [ChatPromptMessage] = []
        let trimmedSystem = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSystem.isEmpty {
            messages.append(ChatPromptMessage(role: ChatPromptMessage.roleSystem, content: trimmedSystem))
        }
        messages.append(contentsOf: history)
        return messages
    }

    nonisolated static func fallbackChatML(messages: [ChatPromptMessage], addGenerationPrompt: Bool) -> String {
        let endMarker = "<|" + "im_end|>"
        var formatted = ""
        for message in messages {
            formatted += "<|im_start|>\(message.role)\n\(message.content)\(endMarker)\n"
        }
        if addGenerationPrompt {
            formatted += "<|im_start|>assistant\n"
        }
        return formatted
    }

    #if canImport(llama)
    nonisolated static func applyTemplate(
        messages: [ChatPromptMessage],
        template: String,
        addGenerationPrompt: Bool
    ) -> String? {
        guard !messages.isEmpty else { return nil }
        guard !template.isEmpty else { return nil }

        return messages.withStableChatMessagePointers { messagePointer, messageCount in
            var output = [CChar](repeating: 0, count: 256_000)
            let written = template.withCString { templateCString in
                Int(
                    llama_chat_apply_template(
                        templateCString,
                        messagePointer,
                        messageCount,
                        addGenerationPrompt,
                        &output,
                        Int32(output.count)
                    )
                )
            }
            guard written > 0, written < output.count else { return nil }
            output[written] = 0
            guard let formatted = String(validatingUTF8: output), !formatted.isEmpty else {
                return nil
            }
            return formatted
        }
    }
    #endif
}

#if canImport(llama)
private extension Array where Element == ChatPromptMessage {
    nonisolated func withStableChatMessagePointers<R>(
        _ body: (UnsafePointer<llama_chat_message>?, Int) -> R
    ) -> R {
        let roles = map(\.role)
        let contents = map(\.content)
        return roles.withCStringPointers { rolePointers in
            contents.withCStringPointers { contentPointers in
                var chatMessages = [llama_chat_message]()
                chatMessages.reserveCapacity(count)
                for index in indices {
                    chatMessages.append(
                        llama_chat_message(
                            role: rolePointers[index],
                            content: contentPointers[index]
                        )
                    )
                }
                return chatMessages.withUnsafeBufferPointer { buffer in
                    body(buffer.baseAddress, buffer.count)
                }
            }
        }
    }
}

private extension Array where Element == String {
    nonisolated func withCStringPointers<R>(_ body: ([UnsafePointer<CChar>]) -> R) -> R {
        var allocated = [UnsafeMutablePointer<CChar>]()
        defer {
            for pointer in allocated {
                pointer.deallocate()
            }
        }

        var pointers = [UnsafePointer<CChar>]()
        pointers.reserveCapacity(count)
        for string in self {
            let utf8 = string.utf8CString
            let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: utf8.count)
            utf8.withUnsafeBufferPointer { source in
                guard let baseAddress = source.baseAddress else { return }
                buffer.initialize(from: baseAddress, count: source.count)
            }
            allocated.append(buffer)
            pointers.append(UnsafePointer(buffer))
        }
        return body(pointers)
    }
}
#endif
