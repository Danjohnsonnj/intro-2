import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class ModelStore {
    private(set) var selectionState: ModelManager.SelectionDisplayState = .noSelection
    private(set) var isLoadingModel = false
    private(set) var lastActionError: String?

    var showsNoModelBanner: Bool {
        !isModelReady
    }

    var isModelReady: Bool {
        guard case .ready = selectionState else { return false }
        return !ModelManager.didLastLoadFail
    }

    var showsForgetModel: Bool {
        if case .ready = selectionState { return true }
        return false
    }

    var activeModelLabel: String {
        activeModelDetail
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
        if isModelReady {
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
        SharedLlamaInference.scheduleWarmFromPersistedSelection()
    }

    func refreshFromManager() {
        selectionState = ModelManager.selectionDisplayState()
    }

    func importModel(from url: URL) async {
        lastActionError = nil
        isLoadingModel = true
        defer { isLoadingModel = false }

        do {
            try ModelManager.setSelection(from: url)
            refreshFromManager()
            try await SharedLlamaInference.shared.withSession(unloadOnExit: false) { _ in }
            refreshFromManager()
        } catch {
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
        refreshFromManager()
    }

    func warmLoadIfNeeded() async {
        guard ModelManager.hasReadableSelection else {
            refreshFromManager()
            return
        }
        guard !isModelReady else { return }

        lastActionError = nil
        isLoadingModel = true
        defer { isLoadingModel = false }

        do {
            try await SharedLlamaInference.shared.withSession(unloadOnExit: false) { _ in }
            refreshFromManager()
        } catch {
            lastActionError = error.localizedDescription
            refreshFromManager()
        }
    }
}
