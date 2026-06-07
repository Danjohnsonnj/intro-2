import SwiftUI

struct NoModelBannerView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text("No model loaded")
                .font(.bannerBody)
                .foregroundStyle(Theme.bannerText)
            Spacer()
            Text("Settings →")
                .font(.bannerBody.weight(.semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.bannerBackground(colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.bannerBorder(colorScheme), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .padding(.horizontal, Theme.Spacing.listRowHorizontal)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No model loaded. Open Settings.")
    }
}

#Preview {
    NoModelBannerView()
        .themedScreen()
}
