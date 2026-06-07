import SwiftUI

// MARK: - Monochrome Unicode glyphs (not Apple Color Emoji)

/// On iOS, many Unicode symbols (e.g. ⚙ U+2699) default to **emoji presentation** in `Text` —
/// multi-color, ignoring `foregroundStyle`. Canonical mock glyphs must be **text presentation**:
/// monochrome and tintable with design tokens (e.g. `Theme.accent`).
///
/// **Rule:** For any symbol used as a tinted UI glyph (nav, toolbar, status), use this helper —
/// not raw `Text("⚙")` or `Label(..., systemImage:)` when the mock specifies a text character.
///
/// - Append **U+FE0E** (text presentation selector) per Unicode TR15
/// - Render with `Text(verbatim:)` + `.foregroundStyle(token)`
/// - Do **not** use emoji strings from the emoji keyboard (often include U+FE0F)
enum TextPresentationGlyph {
    private static let textPresentationSelector = "\u{FE0E}"
    private static let emojiPresentationSelector = "\u{FE0F}"

    /// Scalars that commonly emoji-default on iOS when used in SwiftUI `Text`.
    private static let emojiProneSymbols: Set<String> = [
        "\u{2699}", // ⚙ gear — settings nav (canonical mock)
        "\u{2692}", // ⚒
        "\u{2709}", // ✉ envelope
        "\u{260E}", // ☎ telephone
        "\u{26A1}", // ⚡
    ]

    /// Returns a string safe for tintable `Text`: appends U+FE0E when the symbol emoji-defaults.
    static func monochrome(_ base: String) -> String {
        let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }

        if trimmed.hasSuffix(textPresentationSelector) || trimmed.hasSuffix(emojiPresentationSelector) {
            return trimmed
        }

        if emojiProneSymbols.contains(trimmed) || trimmed == "⚙" {
            return trimmed + textPresentationSelector
        }

        return trimmed
    }

    /// Tintable UI symbol matching canonical nav mock typography (22pt, weight 300/light).
    static func navGlyph(
        _ base: String,
        color: Color = Theme.accent,
        size: CGFloat = 22,
        weight: Font.Weight = .light
    ) -> Text {
        Text(verbatim: monochrome(base))
            .font(.system(size: size, weight: weight))
            .foregroundStyle(color)
    }
}

/// Flat bronze nav glyph on 44×44 tap target (HTML `.icon-btn` / `.back-btn`).
struct InstrumentTintedGlyph: View {
    let base: String
    var color: Color = Theme.accent

    var body: some View {
        TextPresentationGlyph.navGlyph(base, color: color)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
    }
}
