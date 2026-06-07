import SwiftUI

/// Settings-style grouped surface from canonical HTML mocks (flat card, hairline border, inset highlight).
struct InstrumentSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .instrumentSectionHeaderStyle(colorScheme)
                .padding(.horizontal, 6)

            InstrumentGroup {
                content
            }
        }
    }
}

struct InstrumentGroup<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Theme.surface(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.border(colorScheme), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .fill(Theme.surfaceHighlight(colorScheme))
                .frame(height: 1)
                .padding(.horizontal, 1)
        }
    }
}

struct InstrumentStackedRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: String
    let detail: String
    var detailColor: Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.instrumentRowLabel)
                .foregroundStyle(Theme.textPrimary(colorScheme))
            Text(detail)
                .font(.instrumentRowDetail)
                .foregroundStyle(detailColor ?? Theme.textTertiary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Theme.surface(colorScheme))
    }
}

struct InstrumentActionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.instrumentRowAction)
                    .foregroundStyle(Theme.accent)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Theme.surface(colorScheme))
        }
        .buttonStyle(.plain)
    }
}

struct InstrumentInlineRow<Trailing: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            trailing()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Theme.surface(colorScheme))
    }
}

struct InstrumentDestructiveRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.instrumentRowAction)
                .foregroundStyle(Theme.destructive)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

struct InstrumentDivider: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Divider()
            .overlay(Theme.border(colorScheme))
    }
}
