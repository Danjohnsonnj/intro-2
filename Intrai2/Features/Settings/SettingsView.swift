import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        List {
            Section {
                Text("Model import and inference settings arrive in Slice 1.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                    .listRowBackground(Theme.surface(colorScheme))
            } header: {
                Text("Model")
            }

            Section {
                Text("System prompt, context length, and temperature arrive in Slice 6.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary(colorScheme))
                    .listRowBackground(Theme.surface(colorScheme))
            } header: {
                Text("Inference")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background(colorScheme))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .preferredColorScheme(.dark)
}
