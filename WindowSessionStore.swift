import SwiftUI
import AppKit

@MainActor
final class WindowSessionStore: ObservableObject {
    static let shared = WindowSessionStore()

    private let restorableWindowIDsKey = "Quartz.restorable.window.ids"
    private let legacyTextKey = "Quartz_text_persistence"
    private let legacyCanvasKey = "Quartz_canvas_shapes"

    private var launchQueue: [UUID]
    private var orderedWindowIDs: [UUID]
    private var openWindowIDs = Set<UUID>()
    private var nonEmptyWindowIDs = Set<UUID>()
    private var hasRestoredRemainingWindows = false
    private var isTerminating = false
    private var observers: [NSObjectProtocol] = []

    private init() {
        let savedWindowIDs = UserDefaults.standard
            .stringArray(forKey: restorableWindowIDsKey)?
            .compactMap(UUID.init(uuidString:))
            ?? []

        self.launchQueue = savedWindowIDs
        self.orderedWindowIDs = savedWindowIDs

        migrateLegacySessionIfNeeded()
        observeAppTermination()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func consumeLaunchWindowID() -> UUID {
        if !launchQueue.isEmpty {
            let windowID = launchQueue.removeFirst()
            ensureKnown(windowID)
            return windowID
        }

        let windowID = UUID()
        ensureKnown(windowID)
        return windowID
    }

    func makeNewWindowID() -> UUID {
        let windowID = UUID()
        ensureKnown(windowID)
        persistRestorableWindowIDs()
        return windowID
    }

    func restoreRemainingWindows(with openWindow: OpenWindowAction) {
        guard !hasRestoredRemainingWindows else { return }

        hasRestoredRemainingWindows = true

        for windowID in launchQueue {
            ensureKnown(windowID)
            openWindow(value: windowID)
        }

        launchQueue.removeAll()
    }

    func markWindowOpened(_ windowID: UUID) {
        ensureKnown(windowID)
        openWindowIDs.insert(windowID)
        persistRestorableWindowIDs()
    }

    func markWindowClosed(_ windowID: UUID) {
        guard !isTerminating else { return }

        openWindowIDs.remove(windowID)
        persistRestorableWindowIDs()
    }

    func updateText(_ text: String, for windowID: UUID) {
        ensureKnown(windowID)

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nonEmptyWindowIDs.remove(windowID)
        } else {
            nonEmptyWindowIDs.insert(windowID)
        }

        persistRestorableWindowIDs()
    }

    func beginTermination() {
        guard !isTerminating else { return }

        isTerminating = true
        persistRestorableWindowIDs()
    }

    private func ensureKnown(_ windowID: UUID) {
        if !orderedWindowIDs.contains(windowID) {
            orderedWindowIDs.append(windowID)
        }
    }

    private func persistRestorableWindowIDs() {
        let restorableWindowIDs = orderedWindowIDs
            .filter { openWindowIDs.contains($0) && nonEmptyWindowIDs.contains($0) }
            .map(\.uuidString)

        UserDefaults.standard.set(restorableWindowIDs, forKey: restorableWindowIDsKey)
    }

    private func observeAppTermination() {
        let observer = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.beginTermination()
            }
        }

        observers.append(observer)
    }

    private func migrateLegacySessionIfNeeded() {
        guard launchQueue.isEmpty else { return }

        let defaults = UserDefaults.standard
        let legacyText = defaults.string(forKey: legacyTextKey) ?? ""
        let legacyCanvas = defaults.data(forKey: legacyCanvasKey)
        let hasLegacyText = !legacyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        guard hasLegacyText || legacyCanvas != nil else { return }

        let windowID = UUID()
        let prefix = "Quartz.window.\(windowID.uuidString)"

        defaults.set(legacyText, forKey: "\(prefix).text")

        if let legacyCanvas {
            defaults.set(legacyCanvas, forKey: "\(prefix).canvas.shapes")
        }

        ensureKnown(windowID)

        if hasLegacyText {
            launchQueue = [windowID]
            nonEmptyWindowIDs.insert(windowID)
            defaults.set([windowID.uuidString], forKey: restorableWindowIDsKey)
        }
    }
}
