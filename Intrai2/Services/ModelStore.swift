import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ModelStore {
    private(set) var selectionState: ModelManager.SelectionDisplayState = .noSelection
    private(set) var isLoadingModel = false
    private(set) var isInferenceReady = false
    private(set) var lastActionError: String?

    /// No usable model file, or the last runtime load failed.
    var showsNoModelBanner: Bool {
        switch selectionState {
        case .noSelection, .missingFile:
            true
        case .ready:
            ModelManager.didLastLoadFail
        }
    }

    /// Runtime has a loaded model — use for status UI and Slice 3+ send gating.
    var isModelReady: Bool {
        isInferenceReady
    }

    var showsForgetModel: Bool {
        if case .ready = selectionState { return true }
        return false
    }

    var activeModelDetail: String {
        switch selectionState {
        case .noSelection:
            "None"
        case .ready(let name, _):
            name
        case .missingFile:
            "Missing file"
        }
    }

    func activeModelDetailColor(for scheme: ColorScheme) -> Color {
        switch selectionState {
        case .ready:
            Theme.textTertiary(scheme)
        case .noSelection, .missingFile:
            Theme.textTertiary(scheme)
        }
    }

    var statusLabel: String {
        if isInferenceReady {
            return "Model loaded"
        }
        if ModelManager.didLastLoadFail {
            return "Load failed"
        }
        return "Ready"
    }

    func bootstrap() {
        ModelManager.validateSelection()
        refreshFromManager()
        Task(priority: .utility) {
            await warmLoadIfNeeded()
        }
    }

    func refreshFromManager() {
        selectionState = ModelManager.selectionDisplayState()
        if case .noSelection = selectionState {
            isInferenceReady = false
        }
        if case .missingFile = selectionState {
            isInferenceReady = false
        }
    }

    func importModel(from url: URL) async {
        lastActionError = nil
        isLoadingModel = true
        defer { isLoadingModel = false }

        do {
            try ModelManager.setSelection(from: url)
            refreshFromManager()
            try await SharedLlamaInference.shared.withSession(unloadOnExit: false) { _ in }
            isInferenceReady = true
            refreshFromManager()
        } catch {
            isInferenceReady = false
            lastActionError = error.localizedDescription
            refreshFromManager()
        }
    }

    func forgetModel() async {
        lastActionError = nil
        isLoadingModel = true
        defer { isLoadingModel = false }

        await SharedLlamaInference.shared.unloadIfLoaded()
        ModelManager.clearSelection()
        isInferenceReady = false
        refreshFromManager()
    }

    func warmLoadIfNeeded() async {
        guard ModelManager.hasReadableSelection else {
            refreshFromManager()
            return
        }
        guard !isInferenceReady else { return }

        lastActionError = nil
        isLoadingModel = true
        defer { isLoadingModel = false }

        do {
            try await SharedLlamaInference.shared.withSession(unloadOnExit: false) { _ in }
            isInferenceReady = true
            refreshFromManager()
        } catch {
            isInferenceReady = false
            lastActionError = error.localizedDescription
            refreshFromManager()
        }
    }
}
