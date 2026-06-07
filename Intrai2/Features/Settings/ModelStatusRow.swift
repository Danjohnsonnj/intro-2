import SwiftUI

struct ModelStatusRow: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: String
    let isReady: Bool
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isLoading {
                ProgressView()
                    .controlSize(.mini)
                    .tint(Theme.textTertiary(colorScheme))
            } else {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
            }
            Text(displayLabel)
                .instrumentStatusPillStyle(color: textColor)
        }
    }

    private var displayLabel: String {
        if isLoading { "Loading model…" }
        else { label }
    }

    private var dotColor: Color {
        isReady ? Theme.statusReady : Theme.textTertiary(colorScheme)
    }

    private var textColor: Color {
        if isReady { Theme.statusReady }
        else { Theme.textTertiary(colorScheme) }
    }
}
