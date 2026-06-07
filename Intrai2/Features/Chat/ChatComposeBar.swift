import SwiftUI

/// Chat compose row — layout locked to `chat-ad-idle-generating.html` `.compose-bar`.
/// Previews at bottom guard against regressions (idle / generating / multiline / toggle).
struct ChatComposeBar: View {
    @Binding var text: String
    var isGenerating: Bool
    var isModelReady: Bool
    var canSend: Bool
    var onSend: () -> Void
    var onStop: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    @State private var measuredFieldHeight = Theme.Spacing.composeFieldMinHeight

    private var actionMode: ComposeActionMode {
        isGenerating ? .generating : .idle(canSend: canSend)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            composeField
            composeActionButton
        }
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .padding(.vertical, 12)
        .background(Theme.surface(colorScheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.borderStrong(colorScheme))
                .frame(height: 1)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.surfaceHighlight(colorScheme))
                .frame(height: 1)
        }
    }

    private var composeField: some View {
        TextField("Message", text: $text, axis: .vertical)
            .focused($isFocused)
            .lineLimit(1...Theme.Spacing.composeMaxLines)
            .font(.system(size: Theme.ChatTypography.bodySize))
            .lineSpacing(Theme.ChatTypography.composeLineSpacing)
            .foregroundStyle(Theme.textPrimary(colorScheme))
            .padding(.vertical, Theme.Spacing.composeTextVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.composeHorizontalInset)
            .frame(minHeight: Theme.Spacing.composeFieldMinHeight, alignment: .center)
            .background(Theme.background(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.border(colorScheme), lineWidth: 1)
            }
            .onGeometryChange(for: CGFloat.self, of: \.size.height) { _, height in
                measuredFieldHeight = min(
                    max(Theme.Spacing.composeFieldMinHeight, height),
                    Self.composeInputMaxHeight
                )
            }
            .disabled(isGenerating)
            .opacity(isGenerating ? 0.4 : 1)
    }

    /// Separate send and stop buttons — never morph one `Button` label (SwiftUI caches labels).
    @ViewBuilder
    private var composeActionButton: some View {
        switch actionMode {
        case .generating:
            Button(action: onStop) {
                ChatComposeStopGlyph()
            }
            .buttonStyle(ComposeActionButtonStyle())
            .disabled(!isModelReady)
            .opacity(isModelReady ? 1 : 0.45)
            .accessibilityLabel("Stop")
            .frame(width: 44, height: measuredFieldHeight)
            .id(ComposeActionMode.generating)

        case .idle(let canSend):
            Button(action: onSend) {
                ChatComposeSendGlyph()
            }
            .buttonStyle(ComposeActionButtonStyle())
            .disabled(!isModelReady || !canSend)
            .opacity(idleActionOpacity(canSend: canSend))
            .accessibilityLabel("Send")
            .frame(width: 44, height: measuredFieldHeight)
            .id(ComposeActionMode.idle(canSend: canSend))
        }
    }

    private func idleActionOpacity(canSend: Bool) -> Double {
        guard isModelReady else { return 0.45 }
        return canSend ? 1 : 0.45
    }

    /// Mock `.compose-input` max-height 120px.
    private static var composeInputMaxHeight: CGFloat {
        let lineHeight = Theme.ChatTypography.bodySize * 1.35
        let textArea = lineHeight * CGFloat(Theme.Spacing.composeMaxLines)
        return textArea + Theme.Spacing.composeTextVerticalPadding * 2
    }
}

// MARK: - Action mode + glyphs (no conditionals inside Button labels)

private enum ComposeActionMode: Hashable {
    case idle(canSend: Bool)
    case generating
}

/// Bronze 44×44 chrome shared by send and stop (mock `.send-btn`).
private struct ComposeActionChrome<Glyph: View>: View {
    @ViewBuilder var glyph: () -> Glyph

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(Theme.accent)
            glyph()
        }
        .frame(width: 44, height: 44)
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Color(hex: "#FFE4B4").opacity(0.35), lineWidth: 1)
                .blendMode(.overlay)
        }
    }
}

private struct ChatComposeSendGlyph: View {
    var body: some View {
        ComposeActionChrome {
            Text("↑")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.background(.dark))
        }
    }
}

/// Mock `.send-btn.stop::after` — 11×11 square on bronze fill.
private struct ChatComposeStopGlyph: View {
    var body: some View {
        ComposeActionChrome {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Theme.background(.dark))
                .frame(width: 11, height: 11)
        }
    }
}

private struct ComposeActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Layout regression previews (compare to chat-ad-idle-generating.html)

#Preview("Compose — idle") {
    @Previewable @State var text = ""
    ChatComposeBar(
        text: $text,
        isGenerating: false,
        isModelReady: true,
        canSend: false,
        onSend: {},
        onStop: {}
    )
    .themedScreen()
    .preferredColorScheme(.dark)
}

#Preview("Compose — generating") {
    @Previewable @State var text = ""
    ChatComposeBar(
        text: $text,
        isGenerating: true,
        isModelReady: true,
        canSend: false,
        onSend: {},
        onStop: {}
    )
    .themedScreen()
    .preferredColorScheme(.dark)
}

#Preview("Compose — multiline") {
    @Previewable @State var text = "Line one\nLine two\nLine three"
    ChatComposeBar(
        text: $text,
        isGenerating: false,
        isModelReady: true,
        canSend: true,
        onSend: {},
        onStop: {}
    )
    .themedScreen()
    .preferredColorScheme(.dark)
}

#Preview("Compose — toggle send/stop") {
    @Previewable @State var text = ""
    @Previewable @State var isGenerating = false
    VStack(spacing: 20) {
        ChatComposeBar(
            text: $text,
            isGenerating: isGenerating,
            isModelReady: true,
            canSend: !text.isEmpty,
            onSend: { isGenerating = true },
            onStop: { isGenerating = false }
        )
        Button(isGenerating ? "Simulate stop" : "Simulate send") {
            isGenerating.toggle()
        }
        .buttonStyle(.bordered)
    }
    .themedScreen()
    .preferredColorScheme(.dark)
}
