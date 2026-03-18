import SwiftUI
import Combine
import AppKit

enum TextStatType: String, CaseIterable, Identifiable {
    case words = "Words"
    case charactersWithSpaces = "Chars (with spaces)"
    case charactersNoSpaces = "Chars (no spaces)"
    case lines = "Lines"
    case readingTime = "Reading Time"

    var id: String { rawValue }
}

enum QuartzFontSize: CGFloat, CaseIterable, Identifiable {
    case normal = 18
    case large = 24
    case extraLarge = 32

    var id: CGFloat { rawValue }

    var label: String {
        switch self {
        case .normal: return "Normal"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }
}

@MainActor
final class QuartzViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isDarkMode: Bool = true
    @Published var selectedStat: TextStatType = .words
    @Published var fontSize: QuartzFontSize = .normal
    @Published var isPreviewMode: Bool = false
    @Published var isSplitView: Bool = false

    @Published private(set) var cachedStatText: String = "0 words"

    let windowID: UUID

    private let storagePrefix: String
    private var cancellables = Set<AnyCancellable>()

    private enum StorageKey: String {
        case text
        case darkMode
        case selectedStat
        case fontSize
        case previewMode
        case splitView
    }

    private static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter
    }()

    private static let tempFileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm"
        return formatter
    }()

    init(windowID: UUID) {
        self.windowID = windowID
        self.storagePrefix = "Quartz.window.\(windowID.uuidString)"
        loadState()
        setupAutoSave()
        WindowSessionStore.shared.updateText(text, for: windowID)
    }

    private func setupAutoSave() {
        $text
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.saveText()
            }
            .store(in: &cancellables)

        $text
            .dropFirst()
            .sink { [weak self] newText in
                guard let self else { return }
                WindowSessionStore.shared.updateText(newText, for: self.windowID)
            }
            .store(in: &cancellables)

        $text
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] newText in
                self?.updateCachedStats(for: newText)
            }
            .store(in: &cancellables)

        $isDarkMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                self?.save(value, for: .darkMode)
            }
            .store(in: &cancellables)

        $selectedStat
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                self?.save(value.rawValue, for: .selectedStat)
                self?.refreshStats()
            }
            .store(in: &cancellables)

        $fontSize
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                self?.save(Double(value.rawValue), for: .fontSize)
            }
            .store(in: &cancellables)

        $isPreviewMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                self?.save(value, for: .previewMode)
            }
            .store(in: &cancellables)

        $isSplitView
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] value in
                self?.save(value, for: .splitView)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.persistNow()
            }
            .store(in: &cancellables)

        updateCachedStats(for: text)
    }

    private func updateCachedStats(for text: String) {
        cachedStatText = calculateStatText(for: text)
    }

    private func calculateStatText(for text: String) -> String {
        switch selectedStat {
        case .words:
            let count = text.split { $0.isWhitespace || $0.isNewline }.count
            return "\(count) words"
        case .charactersWithSpaces:
            return "\(text.count) chars"
        case .charactersNoSpaces:
            let count = text.filter { !$0.isWhitespace }.count
            return "\(count) chars"
        case .lines:
            if text.isEmpty { return "0 lines" }
            let count = text.components(separatedBy: .newlines).count
            return "\(count) lines"
        case .readingTime:
            let wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
            let minutes = wordCount / 200
            return minutes < 1 ? "< 1 min read" : "\(minutes) min read"
        }
    }

    private func storageKey(_ key: StorageKey) -> String {
        "\(storagePrefix).\(key.rawValue)"
    }

    private func loadState() {
        let defaults = UserDefaults.standard

        text = defaults.string(forKey: storageKey(.text)) ?? ""

        if defaults.object(forKey: storageKey(.darkMode)) != nil {
            isDarkMode = defaults.bool(forKey: storageKey(.darkMode))
        }

        if
            let storedStat = defaults.string(forKey: storageKey(.selectedStat)),
            let selectedStat = TextStatType(rawValue: storedStat)
        {
            self.selectedStat = selectedStat
        }

        let storedFontSize = defaults.double(forKey: storageKey(.fontSize))
        if storedFontSize > 0, let fontSize = QuartzFontSize(rawValue: storedFontSize) {
            self.fontSize = fontSize
        }

        if defaults.object(forKey: storageKey(.previewMode)) != nil {
            isPreviewMode = defaults.bool(forKey: storageKey(.previewMode))
        }

        if defaults.object(forKey: storageKey(.splitView)) != nil {
            isSplitView = defaults.bool(forKey: storageKey(.splitView))
        }
    }

    private func save(_ value: Any, for key: StorageKey) {
        UserDefaults.standard.set(value, forKey: storageKey(key))
    }

    private func saveText() {
        save(text, for: .text)
    }

    @MainActor
    private func persistNow() {
        saveText()
        save(isDarkMode, for: .darkMode)
        save(selectedStat.rawValue, for: .selectedStat)
        save(Double(fontSize.rawValue), for: .fontSize)
        save(isPreviewMode, for: .previewMode)
        save(isSplitView, for: .splitView)
        WindowSessionStore.shared.updateText(text, for: windowID)
    }

    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }

    func clearBoard() {
        withAnimation(.easeOut(duration: 0.2)) {
            text = ""
        }
    }

    var statText: String {
        cachedStatText
    }

    func refreshStats() {
        updateCachedStats(for: text)
    }

    func createTempFile() -> URL {
        let dateString = Self.tempFileDateFormatter.string(from: Date())
        let fileName = "Note \(dateString).txt"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating temp file: \(error)")
            return fileURL
        }
    }

    func exportToDesktop() {
        let dateString = Self.exportDateFormatter.string(from: Date())
        let fileName = "Quartz Note \(dateString).txt"

        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            print("Could not find Desktop directory")
            return
        }

        let fileURL = desktopURL.appendingPathComponent(fileName)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error exporting to Desktop: \(error)")
        }
    }
}
