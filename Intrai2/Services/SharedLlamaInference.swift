import Foundation

struct InferenceSession: Sendable {
    let bridge: LlamaCppBridge
}

enum SharedLlamaInferenceError: LocalizedError {
    case noModelSelected

    var errorDescription: String? {
        switch self {
        case .noModelSelected:
            "No model is selected or the file is not reachable."
        }
    }
}

private nonisolated func makeLlamaRuntimeConfig() -> LlamaCppRuntime.RuntimeConfig {
    LlamaCppRuntime.RuntimeConfig(
        contextWindow: SettingsStore.nCtx,
        promptSlackTokens: 64,
        physicalBatchSize: 1024
    )
}

/// Serializes load → inference → unload so concurrent callers cannot unload mid-generation.
actor SharedLlamaInference {
    static let shared = SharedLlamaInference()

    private var runtime: LlamaCppRuntime
    private let lifecycleLock = AsyncLock()
    private var loadedPath: String?
    private var loadedContextWindow: UInt32?
    private var scopedAccess: ModelManager.ScopedAccess?

    private init() {
        runtime = LlamaCppRuntime(config: makeLlamaRuntimeConfig())
    }

    func withSession<R: Sendable>(
        unloadOnExit: Bool = true,
        _ work: @escaping (InferenceSession) async throws -> R
    ) async throws -> R {
        await lifecycleLock.acquire()
        do {
            try await ensureLoadedLocked()
            let result = try await work(InferenceSession(bridge: runtime))
            if unloadOnExit { await unloadLocked() }
            await lifecycleLock.release()
            return result
        } catch {
            if unloadOnExit { await unloadLocked() }
            await lifecycleLock.release()
            throw error
        }
    }

    func unloadIfLoaded() async {
        await lifecycleLock.acquire()
        await unloadLocked()
        await lifecycleLock.release()
    }

    /// Drop loaded model/context so the next session picks up current SettingsStore values.
    func reloadForSettingsChange() async {
        await lifecycleLock.acquire()
        runtime.unloadModel()
        loadedPath = nil
        loadedContextWindow = nil
        scopedAccess?.end()
        scopedAccess = nil
        runtime = LlamaCppRuntime(config: makeLlamaRuntimeConfig())
        await lifecycleLock.release()
    }

    /// Interrupt an in-flight decode immediately (abort callback + shouldCancel flag).
    func cancelActiveGeneration() {
        runtime.cancelGeneration()
    }

    private func ensureLoadedLocked() async throws {
        guard let access = ModelManager.openSelection() else {
            ModelManager.setLastLoadFailed(true)
            throw SharedLlamaInferenceError.noModelSelected
        }
        try await swapToLoadedModelIfNeeded(access: access)
    }

    private func swapToLoadedModelIfNeeded(access: ModelManager.ScopedAccess) async throws {
        let path = access.path
        let requestedContext = SettingsStore.nCtx
        if loadedPath == path, loadedContextWindow == requestedContext {
            ModelManager.setLastLoadFailed(false)
            access.end()
            return
        }

        runtime.unloadModel()
        scopedAccess?.end()
        scopedAccess = nil
        loadedPath = nil
        loadedContextWindow = nil
        runtime = LlamaCppRuntime(config: makeLlamaRuntimeConfig())

        scopedAccess = access
        do {
            try runtime.loadModel(path: path)
            loadedPath = path
            loadedContextWindow = requestedContext
            ModelManager.setLastLoadFailed(false)
        } catch {
            scopedAccess?.end()
            scopedAccess = nil
            loadedPath = nil
            loadedContextWindow = nil
            ModelManager.setLastLoadFailed(true)
            throw error
        }
    }

    private func unloadLocked() async {
        runtime.unloadModel()
        loadedPath = nil
        loadedContextWindow = nil
        scopedAccess?.end()
        scopedAccess = nil
    }
}
