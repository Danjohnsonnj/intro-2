import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(ModelStore.self) private var modelStore
    @Environment(InferenceSettingsStore.self) private var inferenceSettingsStore

    @State private var isShowingImporter = false
    @State private var importErrorMessage: String?
    @FocusState private var isSystemPromptFocused: Bool

    private var ggufTypes: [UTType] {
        [UTType(filenameExtension: "gguf") ?? .data, .data]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                modelSection
                systemPromptSection
                inferenceSection
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
            inferenceSettingsStore.syncFromStore()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intraiModelAvailabilityDidChange)) { _ in
            modelStore.refreshFromManager()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intraiInferenceSettingsDidChange)) { _ in
            inferenceSettingsStore.syncFromStore()
        }
        .onChange(of: isSystemPromptFocused) { _, isFocused in
            guard !isFocused else { return }
            inferenceSettingsStore.commitSystemPrompt()
        }
    }

    private var modelSection: some View {
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
    }

    private var systemPromptSection: some View {
        InstrumentSection(title: "System prompt") {
            TextEditor(text: Bindable(inferenceSettingsStore).systemPromptDraft)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary(colorScheme))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120, alignment: .topLeading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Theme.codeBackground)
                .focused($isSystemPromptFocused)

            InstrumentDivider()

            Text(inferenceSettingsStore.systemPromptHint)
                .font(.instrumentRowDetail)
                .foregroundStyle(Theme.textTertiary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Theme.surface(colorScheme))
        }
    }

    private var inferenceSection: some View {
        InstrumentSection(title: "Inference") {
            InstrumentStepperRow(
                label: "Context length",
                value: inferenceSettingsStore.contextLengthLabel,
                onDecrement: { inferenceSettingsStore.decrementContextLength(modelStore: modelStore) },
                onIncrement: { inferenceSettingsStore.incrementContextLength(modelStore: modelStore) },
                decrementEnabled: inferenceSettingsStore.canDecrementContextLength,
                incrementEnabled: inferenceSettingsStore.canIncrementContextLength
            )

            InstrumentDivider()

            InstrumentCreativitySliderRow(
                label: "Creativity",
                value: Bindable(inferenceSettingsStore).creativity,
                onEditingChanged: { value in
                    inferenceSettingsStore.setCreativity(value)
                }
            )

            if let inferenceError = inferenceSettingsStore.lastActionError {
                InstrumentDivider()
                Text(inferenceError)
                    .font(.instrumentRowDetail)
                    .foregroundStyle(Theme.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Theme.surface(colorScheme))
            }
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
    .environment(InferenceSettingsStore())
    .themedScreen()
}
