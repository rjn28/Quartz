import SwiftUI
import Combine

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

class QuartzViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var text: String = ""
    @Published var isDarkMode: Bool = true
    @Published var selectedStat: TextStatType = .words
    @Published var fontSize: QuartzFontSize = .normal
    @Published var isPreviewMode: Bool = false
    @Published var isSplitView: Bool = false
    
    // MARK: - Private Properties
    private let textKey = "Quartz_text_persistence"
    private var cancellables = Set<AnyCancellable>()
    
    // Cached statistics (updated with debounce)
    @Published private(set) var cachedStatText: String = "0 words"
    
    // Static DateFormatter (expensive to create, reuse it)
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
    
    // MARK: - Initialization
    init() {
        loadText()
        setupAutoSave()
    }
    
    // MARK: - Logic
    
    private func setupAutoSave() {
        // Debounced save
        $text
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.saveText()
            }
            .store(in: &cancellables)
        
        // Debounced stats update (same timing)
        $text
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] newText in
                self?.updateCachedStats(for: newText)
            }
            .store(in: &cancellables)
        
        // Initial stats
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
            if minutes < 1 {
                return "< 1 min read"
            } else {
                return "\(minutes) min read"
            }
        }
    }
    
    /// Loads the saved text from UserDefaults
    private func loadText() {
        if let savedText = UserDefaults.standard.string(forKey: textKey) {
            self.text = savedText
        }
    }
    
    /// Saves the current text to UserDefaults
    private func saveText() {
        UserDefaults.standard.set(text, forKey: textKey)
    }
    
    /// Toggles the visual theme
    func toggleTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isDarkMode.toggle()
        }
    }
    
    /// Clears the Quartz content
    func clearBoard() {
        withAnimation(.easeOut(duration: 0.2)) {
            text = ""
        }
    }
    
    /// Returns the formatted string for the selected statistic (uses cached value)
    var statText: String {
        cachedStatText
    }
    
    /// Force refresh stats when user changes stat type
    func refreshStats() {
        updateCachedStats(for: text)
    }
    
    /// Creates a temporary file for drag and drop
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
    /// Exports the current text to a file on the Desktop
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
