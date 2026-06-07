import Foundation

/// Persists the user's chosen `.gguf` as a security-scoped bookmark.
enum ModelManager {
    private nonisolated static let bookmarkKey = "intrai2.selectedGGUFBookmark"
    private nonisolated static let lastLoadFailedKey = "intrai2.lastModelLoadFailed"

    struct ScopedAccess: Sendable {
        let url: URL
        private let stopAccess: @Sendable () -> Void

        nonisolated init(url: URL, stopAccess: @escaping @Sendable () -> Void) {
            self.url = url
            self.stopAccess = stopAccess
        }

        nonisolated func end() {
            stopAccess()
        }

        nonisolated var path: String {
            url.standardizedFileURL.path
        }
    }

    enum SelectionDisplayState: Equatable, Sendable {
        case noSelection
        case ready(name: String, byteString: String)
        case missingFile
    }

    nonisolated static var hasBookmark: Bool {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return false }
        return !data.isEmpty
    }

    nonisolated static var hasReadableSelection: Bool {
        guard let access = openSelection() else { return false }
        access.end()
        return true
    }

    nonisolated static func clearSelection() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        UserDefaults.standard.set(false, forKey: lastLoadFailedKey)
        notifyModelAvailabilityChanged()
    }

    nonisolated static func setSelection(from pickedURL: URL) throws {
        let accessed = pickedURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                pickedURL.stopAccessingSecurityScopedResource()
            }
        }

        let data = try pickedURL.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(data, forKey: bookmarkKey)
        UserDefaults.standard.set(false, forKey: lastLoadFailedKey)
        notifyModelAvailabilityChanged()
    }

    nonisolated static func openSelection() -> ScopedAccess? {
        openBookmark(forKey: bookmarkKey)
    }

    nonisolated static func selectionDisplayState() -> SelectionDisplayState {
        selectionDisplayState(forKey: bookmarkKey)
    }

    nonisolated static func validateSelection() {
        validateBookmark(forKey: bookmarkKey, clear: clearSelection)
    }

    nonisolated static var didLastLoadFail: Bool {
        UserDefaults.standard.bool(forKey: lastLoadFailedKey)
    }

    nonisolated static func setLastLoadFailed(_ failed: Bool) {
        let prior = UserDefaults.standard.bool(forKey: lastLoadFailedKey)
        UserDefaults.standard.set(failed, forKey: lastLoadFailedKey)
        if prior != failed {
            notifyModelAvailabilityChanged()
        }
    }

    nonisolated private static func notifyModelAvailabilityChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .intraiModelAvailabilityDidChange, object: nil)
        }
    }

    nonisolated private static func openBookmark(forKey key: String) -> ScopedAccess? {
        guard let data = UserDefaults.standard.data(forKey: key), !data.isEmpty else {
            return nil
        }
        guard let (url, stale) = resolveBookmark(data: data) else {
            return nil
        }
        if stale {
            return nil
        }

        let commenced = url.startAccessingSecurityScopedResource()
        let (reachable, _) = selectionReachability(url: url)
        if !commenced && !reachable {
            return nil
        }
        if commenced && !reachable {
            url.stopAccessingSecurityScopedResource()
            return nil
        }

        return ScopedAccess(url: url) {
            if commenced {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }

    nonisolated private static func selectionDisplayState(forKey key: String) -> SelectionDisplayState {
        guard let data = UserDefaults.standard.data(forKey: key), !data.isEmpty else {
            return .noSelection
        }
        guard let (url, stale) = resolveBookmark(data: data), !stale else {
            return .missingFile
        }

        let commenced = url.startAccessingSecurityScopedResource()
        defer {
            if commenced {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let (reachable, _) = selectionReachability(url: url)
        guard reachable else {
            return .missingFile
        }
        return .ready(name: url.lastPathComponent, byteString: byteString(for: url))
    }

    nonisolated private static func validateBookmark(forKey key: String, clear: () -> Void) {
        guard let data = UserDefaults.standard.data(forKey: key), !data.isEmpty else {
            return
        }
        guard let (_, stale) = resolveBookmark(data: data) else {
            clear()
            return
        }
        if stale {
            clear()
        }
    }

    private nonisolated static func resolveBookmark(data: Data) -> (URL, Bool)? {
        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else {
            return nil
        }
        return (url, stale)
    }

    private nonisolated static func byteString(for url: URL) -> String {
        if let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
           let size = values.fileSize {
            return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
        }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? UInt64 else {
            return "—"
        }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private nonisolated static func selectionReachability(url: URL) -> (Bool, String) {
        if (try? url.checkResourceIsReachable()) == true {
            return (true, "checkResourceIsReachable")
        }
        if let values = try? url.resourceValues(forKeys: [.isRegularFileKey]),
           values.isRegularFile == true {
            return (true, "resourceValues.isRegularFile")
        }
        if FileManager.default.fileExists(atPath: url.path) {
            return (true, "fileExistsAtPath")
        }
        return (false, "allChecksFailed")
    }
}
