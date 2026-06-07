import SwiftUI

/// Design-handoff tokens mapped to semantic SwiftUI colors (dark-first, system light supported).
enum Theme {
    enum Spacing {
        static let screenHorizontal: CGFloat = 18
        static let rowVertical: CGFloat = 14
        static let section: CGFloat = 28
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

private struct ThemedScreenModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Theme.background(colorScheme).ignoresSafeArea())
            .foregroundStyle(Theme.textPrimary(colorScheme))
            .tint(Theme.accent)
    }
}

extension View {
    func themedScreen() -> some View {
        modifier(ThemedScreenModifier())
    }
}
