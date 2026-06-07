import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ModelStore.self) private var modelStore

    @State private var isShowingImporter = false
    @State private var importErrorMessage: String?

    private var ggufTypes: [UTType] {
        [UTType(filenameExtension: "gguf") ?? .data, .data]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                InstrumentSection(title: "Model") {
                    InstrumentStackedRow(
                        label: "Active model",
                        detail: modelStore.activeModelDetail,
                        detailColor: modelStore.activeModelDetailColor(for: colorScheme)
                    )

                    InstrumentDivider()

                    InstrumentActionRow(title: "Import GGUF…") {
                        isShowingImporter = true
                    }

                    InstrumentDivider()

                    InstrumentInlineRow {
                        ModelStatusRow(
                            label: modelStore.statusLabel,
                            isReady: modelStore.isModelReady,
                            isLoading: modelStore.isLoadingModel
                        )
                    }

                    if modelStore.showsForgetModel {
                        InstrumentDivider()
                        InstrumentDestructiveRow(title: "Forget model") {
                            Task { await modelStore.forgetModel() }
                        }
                    }

                    if let message = statusMessage {
                        InstrumentDivider()
                        Text(message)
                            .font(.instrumentRowDetail)
                            .foregroundStyle(Theme.destructive)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Theme.surface(colorScheme))
                    }
                }

                InstrumentSection(title: "Inference") {
                    Text("System prompt, context length, and temperature — Slice 6.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary(colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Theme.surface(colorScheme))
                }
            }
            .padding(.horizontal, Theme.Spacing.settingsHorizontal)
            .padding(.top, Theme.Spacing.section)
            .padding(.bottom, 20)
        }
        .background(Theme.background(colorScheme))
        .navigationTitle("Settings")
        .instrumentNavigationBar()
        .instrumentHidesSystemBackButton()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                InstrumentBackButton()
            }
            .instrumentFlatToolbarItem()
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: ggufTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .onAppear {
            modelStore.refreshFromManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intraiModelAvailabilityDidChange)) { _ in
            modelStore.refreshFromManager()
        }
    }

    private var statusMessage: String? {
        if let importErrorMessage { return importErrorMessage }
        if let actionError = modelStore.lastActionError { return actionError }
        return nil
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        importErrorMessage = nil
        switch result {
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            Task {
                defer {
                    if accessed {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                await modelStore.importModel(from: url)
                if let actionError = modelStore.lastActionError {
                    importErrorMessage = actionError
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(ModelStore())
    .themedScreen()
}
