import MarkdownUI
import SwiftUI

enum ChatMarkdownTheme {
    static func theme(colorScheme: ColorScheme, textAlignment: TextAlignment) -> MarkdownUI.Theme {
        let primary = Theme.textPrimary(colorScheme)
        let secondary = Theme.textSecondary(colorScheme)
        let codeBackground = Theme.codeBackground

        return MarkdownUI.Theme()
            .text {
                FontSize(Theme.ChatTypography.bodySize)
                ForegroundColor(primary)
            }
            .strong {
                FontWeight(.semibold)
            }
            .emphasis {
                FontStyle(.italic)
            }
            .link {
                ForegroundColor(Theme.accent)
            }
            .heading1 { configuration in
                headingLabel(
                    configuration.label,
                    colorScheme: colorScheme,
                    textAlignment: textAlignment,
                    fontSize: .em(1.5),
                    weight: .semibold,
                    top: 12,
                    bottom: 8
                )
            }
            .heading2 { configuration in
                headingLabel(
                    configuration.label,
                    colorScheme: colorScheme,
                    textAlignment: textAlignment,
                    fontSize: .em(1.3),
                    weight: .semibold,
                    top: 10,
                    bottom: 6
                )
            }
            .heading3 { configuration in
                headingLabel(
                    configuration.label,
                    colorScheme: colorScheme,
                    textAlignment: textAlignment,
                    fontSize: .em(1.15),
                    weight: .semibold,
                    top: 8,
                    bottom: 4
                )
            }
            .heading4 { configuration in
                headingLabel(
                    configuration.label,
                    colorScheme: colorScheme,
                    textAlignment: textAlignment,
                    fontSize: .em(1),
                    weight: .semibold,
                    top: 6,
                    bottom: 4
                )
            }
            .heading5 { configuration in
                headingLabel(
                    configuration.label,
                    colorScheme: colorScheme,
                    textAlignment: textAlignment,
                    fontSize: .em(0.9),
                    weight: .semibold,
                    top: 4,
                    bottom: 2
                )
            }
            .heading6 { configuration in
                headingLabel(
                    configuration.label,
                    colorScheme: colorScheme,
                    textAlignment: textAlignment,
                    fontSize: .em(0.85),
                    weight: .semibold,
                    foreground: Theme.textSecondary(colorScheme),
                    top: 4,
                    bottom: 2
                )
            }
            .code {
                FontFamilyVariant(.monospaced)
                FontSize(14)
                BackgroundColor(codeBackground)
            }
            .codeBlock { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamilyVariant(.monospaced)
                        FontSize(13)
                        ForegroundColor(secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: textAlignment == .trailing ? .trailing : .leading)
                    .background(codeBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                            .strokeBorder(Theme.border(colorScheme), lineWidth: 1)
                    }
                    .markdownMargin(top: 10, bottom: 10)
            }
            .paragraph { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontSize(Theme.ChatTypography.bodySize)
                        ForegroundColor(primary)
                    }
                    .lineSpacing(Theme.ChatTypography.bubbleLineSpacing)
                    .multilineTextAlignment(textAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .markdownMargin(top: 0, bottom: 8)
            }
            .list { configuration in
                configuration.label
                    .markdownMargin(top: 0, bottom: 8)
            }
            .listItem { configuration in
                configuration.label
                    .markdownMargin(top: 0, bottom: 4)
            }
    }

    @ViewBuilder
    private static func headingLabel(
        _ label: some View,
        colorScheme: ColorScheme,
        textAlignment: TextAlignment,
        fontSize: RelativeSize,
        weight: Font.Weight,
        foreground: Color? = nil,
        top: CGFloat,
        bottom: CGFloat
    ) -> some View {
        label
            .relativeLineSpacing(.em(0.1))
            .multilineTextAlignment(textAlignment)
            .fixedSize(horizontal: false, vertical: true)
            .markdownMargin(top: top, bottom: bottom)
            .markdownTextStyle {
                FontWeight(weight)
                FontSize(fontSize)
                ForegroundColor(foreground ?? Theme.textPrimary(colorScheme))
            }
    }
}
