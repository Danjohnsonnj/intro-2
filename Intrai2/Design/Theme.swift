import SwiftUI
import UIKit

/// Design-handoff + canonical HTML mock tokens (dark-first, system light supported).
enum Theme {
    enum Spacing {
        static let screenHorizontal: CGFloat = 18
        static let listRowHorizontal: CGFloat = 22
        static let listRowVertical: CGFloat = 18
        static let rowVertical: CGFloat = 14
        static let section: CGFloat = 28
        static let settingsHorizontal: CGFloat = 18
        /// Gap between list nav action glyphs (mock `.nav-actions`).
        static let navActionGap: CGFloat = 4
        /// Trailing inset for list nav action cluster (mock `.nav-bar` padding-right 8px).
        static let navBarTrailing: CGFloat = 8
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 18
    }

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#121110") : Color(hex: "#F5F2ED")
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#1C1B19") : Color(hex: "#FFFFFF")
    }

    static func surfaceRaised(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#252422") : Color(hex: "#EDEAE6")
    }

    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(hex: "#F0EDE8").opacity(0.08)
            : Color(hex: "#121110").opacity(0.08)
    }

    static func borderStrong(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(hex: "#F0EDE8").opacity(0.14)
            : Color(hex: "#121110").opacity(0.14)
    }

    static func surfaceHighlight(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(hex: "#FFF8F0").opacity(0.04)
            : Color.white.opacity(0.35)
    }

    static func bannerBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 180 / 255, green: 140 / 255, blue: 60 / 255).opacity(0.10)
            : Color(red: 180 / 255, green: 140 / 255, blue: 60 / 255).opacity(0.08)
    }

    static func bannerBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 180 / 255, green: 140 / 255, blue: 60 / 255).opacity(0.22)
            : Color(red: 180 / 255, green: 140 / 255, blue: 60 / 255).opacity(0.18)
    }

    static func textPrimary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#F0EDE8") : Color(hex: "#121110")
    }

    static func textSecondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#9A9690") : Color(hex: "#6B6762")
    }

    static func textTertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#6B6762") : Color(hex: "#9A9690")
    }

    static let accent = Color(hex: "#CDA963")
    static let accentSubtle = Color(hex: "#CDA963").opacity(0.12)
    static let userBubble = Color(hex: "#CDA963").opacity(0.11)
    static let codeBackground = Color(hex: "#2A2826")
    static let statusReady = Color(hex: "#7A9A7E")
    static let bannerText = Color(hex: "#C4A862")
    static let destructive = Color(hex: "#B85C5C")
    static let swipeDelete = Color(hex: "#C94A4A")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Typography (canonical mock treatments)

extension Font {
    static let instrumentSectionHeader = Font.system(size: 11, weight: .semibold)
    static let instrumentRowLabel = Font.system(size: 16, weight: .medium)
    static let instrumentRowDetail = Font.system(size: 13, weight: .regular, design: .monospaced)
    static let instrumentRowAction = Font.system(size: 16, weight: .medium)
    static let instrumentStatusPill = Font.system(size: 11, weight: .semibold)
    static let listRowTitle = Font.system(size: 17, weight: .medium)
    static let listRowTimestamp = Font.system(size: 12, weight: .medium)
    static let emptyStateTitle = Font.system(size: 17, weight: .medium)
    static let emptyStateHint = Font.system(size: 15, weight: .regular)
    static let bannerBody = Font.system(size: 13, weight: .medium)
}

extension View {
    func instrumentSectionHeaderStyle(_ scheme: ColorScheme) -> some View {
        font(.instrumentSectionHeader)
            .kerning(0.66)
            .textCase(.uppercase)
            .foregroundStyle(Theme.textTertiary(scheme))
    }

    func instrumentStatusPillStyle(color: Color) -> some View {
        font(.instrumentStatusPill)
            .kerning(0.66)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }

    func listTimestampStyle(_ scheme: ColorScheme) -> some View {
        font(.listRowTimestamp)
            .kerning(0.48)
            .textCase(.uppercase)
            .monospacedDigit()
            .foregroundStyle(Theme.textTertiary(scheme))
    }
}

// MARK: - Screen + navigation chrome

private struct ThemedScreenModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Theme.background(colorScheme).ignoresSafeArea())
            .foregroundStyle(Theme.textPrimary(colorScheme))
            .tint(Theme.accent)
            .preferredColorScheme(.dark)
    }
}

struct InstrumentNavigationBarModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background(colorScheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear { Self.applyAppearance(colorScheme: colorScheme) }
            .onChange(of: colorScheme) { _, newScheme in
                Self.applyAppearance(colorScheme: newScheme)
            }
    }

    private static func applyAppearance(colorScheme: ColorScheme) {
        let background = UIColor(Theme.background(colorScheme))
        let borderStrong = UIColor(Theme.borderStrong(colorScheme))
        let highlight = UIColor(Theme.surfaceHighlight(colorScheme))

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = background
        appearance.shadowColor = borderStrong
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.textPrimary(colorScheme)),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
        ]

        // Hairline under nav bar + inset top highlight (mock `.nav-bar` chrome).
        let highlightLine = UIImage.instrumentNavBarHighlightLine(
            width: UIScreen.main.bounds.width,
            highlight: highlight,
            border: borderStrong
        )
        appearance.shadowImage = highlightLine

        let buttonAppearance = UIBarButtonItemAppearance(style: .plain)
        buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.accent),
        ]
        appearance.buttonAppearance = buttonAppearance
        appearance.doneButtonAppearance = buttonAppearance

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.tintColor = UIColor(Theme.accent)
    }
}

private extension UIImage {
    static func instrumentNavBarHighlightLine(width: CGFloat, highlight: UIColor, border: UIColor) -> UIImage {
        let height: CGFloat = 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            highlight.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: 1))
            border.setFill()
            context.fill(CGRect(x: 0, y: 1, width: width, height: 1))
        }
    }
}

extension View {
    func themedScreen() -> some View {
        modifier(ThemedScreenModifier())
    }

    func instrumentNavigationBar() -> some View {
        modifier(InstrumentNavigationBarModifier())
    }
}
