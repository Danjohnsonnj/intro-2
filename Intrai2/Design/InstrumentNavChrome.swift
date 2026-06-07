import SwiftUI
import UIKit

// MARK: - Flat nav glyphs (canonical mocks — no Liquid Glass)

/// Nav bar symbols from canonical HTML mocks. Use `TextPresentationGlyph` for tintable text glyphs.
enum InstrumentNavSymbol {
    case plus
    case settingsGear
    case back

    var base: String {
        switch self {
        case .plus: "+"
        case .settingsGear: "\u{2699}"
        case .back: "‹"
        }
    }
}

/// Bronze nav glyph on 44×44 tap target; no background fill (per HTML `.icon-btn` / `.back-btn`).
struct InstrumentNavGlyph: View {
    let symbol: InstrumentNavSymbol

    var body: some View {
        InstrumentTintedGlyph(base: symbol.base)
    }
}

struct InstrumentNavIconButton: View {
    let symbol: InstrumentNavSymbol
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            InstrumentNavGlyph(symbol: symbol)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

struct InstrumentBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        InstrumentNavIconButton(symbol: .back, accessibilityLabel: "Back") {
            dismiss()
        }
    }
}

/// List root trailing actions — mock `.nav-actions`: `+` then `⚙`, 4px gap, flat bronze glyphs.
struct InstrumentListNavActions: View {
    let onNewConversation: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.navActionGap) {
            InstrumentNavIconButton(symbol: .plus, accessibilityLabel: "New conversation", action: onNewConversation)

            NavigationLink {
                SettingsView()
            } label: {
                InstrumentNavGlyph(symbol: .settingsGear)
            }
            .buttonStyle(.plain)
            .tint(Theme.accent)
            .accessibilityLabel("Settings")
        }
        .padding(.trailing, Theme.Spacing.navBarTrailing)
    }
}

// MARK: - Toolbar helpers

extension ToolbarContent {
    /// Opt out of iOS 26 Liquid Glass shared backgrounds on bar button items.
    @ToolbarContentBuilder
    func instrumentFlatToolbarItem() -> some ToolbarContent {
        self.sharedBackgroundVisibility(.hidden)
    }
}

extension View {
    /// Left-aligned list root title (mock: title in nav bar leading edge, not centered).
    func instrumentListNavigationTitle(_ title: String) -> some View {
        modifier(InstrumentListNavigationTitleModifier(title: title))
    }

    /// Hide system back chevron; use `InstrumentBackButton` in toolbar instead.
    /// Re-enables edge-swipe pop, which UIKit disables when the system back button is hidden.
    func instrumentHidesSystemBackButton() -> some View {
        modifier(InstrumentHidesSystemBackButtonModifier())
    }
}

// MARK: - Edge-swipe pop with custom back button

private struct InstrumentHidesSystemBackButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .background(InstrumentInteractivePopEnabler())
    }
}

/// Restores `interactivePopGestureRecognizer` when the system back button is hidden.
private struct InstrumentInteractivePopEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InstrumentInteractivePopEnablerViewController {
        InstrumentInteractivePopEnablerViewController()
    }

    func updateUIViewController(_ uiViewController: InstrumentInteractivePopEnablerViewController, context: Context) {
        uiViewController.enableInteractivePopIfNeeded()
    }
}

private final class InstrumentInteractivePopEnablerViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableInteractivePopIfNeeded()
    }

    func enableInteractivePopIfNeeded() {
        guard let navigationController else { return }
        guard let gesture = navigationController.interactivePopGestureRecognizer else { return }
        gesture.isEnabled = true
        if gesture.delegate !== InstrumentInteractivePopGestureDelegate.shared {
            gesture.delegate = InstrumentInteractivePopGestureDelegate.shared
        }
    }
}

private final class InstrumentInteractivePopGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    static let shared = InstrumentInteractivePopGestureDelegate()

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController = gestureRecognizer.view?.nearestNavigationController else {
            return false
        }
        return navigationController.viewControllers.count > 1
    }
}

private extension UIView {
    var nearestNavigationController: UINavigationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let navigationController = current as? UINavigationController {
                return navigationController
            }
            if let viewController = current as? UIViewController,
               let navigationController = viewController.navigationController {
                return navigationController
            }
            responder = current.next
        }
        return nil
    }
}

private struct InstrumentListNavigationTitleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .kerning(0.17)
                        .foregroundStyle(Theme.textPrimary(colorScheme))
                        .fixedSize()
                }
                .instrumentFlatToolbarItem()
            }
    }
}
