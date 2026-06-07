import Foundation

/// FIFO async mutex. One waiter holds the lock at a time; `acquire` suspends until the previous holder calls `release`.
actor AsyncLock {
    private var locked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if !locked {
            locked = true
            return
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            waiters.append(continuation)
        }
    }

    func release() {
        if waiters.isEmpty {
            locked = false
        } else {
            waiters.removeFirst().resume()
        }
    }

    func withLock<R: Sendable>(_ work: @Sendable () async throws -> R) async rethrows -> R {
        await acquire()
        do {
            let value = try await work()
            release()
            return value
        } catch {
            release()
            throw error
        }
    }
}
