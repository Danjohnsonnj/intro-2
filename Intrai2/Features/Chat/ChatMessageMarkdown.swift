import MarkdownUI
import SwiftUI

/// Stream-safe markdown bubble content — coalesces re-parses while tokens arrive (~16ms).
struct ChatMessageMarkdown: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: String
    let isStreaming: Bool
    let textAlignment: TextAlignment

    @State private var renderedContent = ""
    @State private var coalesceTask: Task<Void, Never>?

    private static let coalesceInterval: Duration = .milliseconds(16)

    var body: some View {
        Markdown(displayText)
            .markdownTheme(ChatMarkdownTheme.theme(colorScheme: colorScheme, textAlignment: textAlignment))
            .frame(maxWidth: .infinity, alignment: textAlignment == .trailing ? .trailing : .leading)
            .onAppear {
                renderedContent = content
            }
            .onChange(of: content) { _, newValue in
                applyContentUpdate(newValue)
            }
            .onChange(of: isStreaming) { _, streaming in
                if !streaming {
                    coalesceTask?.cancel()
                    coalesceTask = nil
                    renderedContent = content
                }
            }
            .onDisappear {
                coalesceTask?.cancel()
                coalesceTask = nil
            }
    }

    private var displayText: String {
        if renderedContent.isEmpty, isStreaming {
            return " "
        }
        return renderedContent
    }

    private func applyContentUpdate(_ newValue: String) {
        guard isStreaming else {
            coalesceTask?.cancel()
            coalesceTask = nil
            renderedContent = newValue
            return
        }

        coalesceTask?.cancel()
        coalesceTask = Task { @MainActor in
            try? await Task.sleep(for: Self.coalesceInterval)
            guard !Task.isCancelled else { return }
            renderedContent = newValue
        }
    }
}
