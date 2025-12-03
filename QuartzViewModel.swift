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

class QuartzViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var text: String = ""
    @Published var isDarkMode: Bool = false
    @Published var selectedStat: TextStatType = .words
    
    // MARK: - Private Properties
    private let textKey = "Quartz_text_persistence"
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadText()
        setupAutoSave()
    }
    
    // MARK: - Logic
    
    private func setupAutoSave() {
        $text
            .dropFirst() // Avoid saving immediately upon load
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.saveText()
            }
            .store(in: &cancellables)
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
    
    /// Returns the formatted string for the selected statistic
    var statText: String {
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
    
    /// Creates a temporary file for drag and drop
    func createTempFile() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm"
        let dateString = formatter.string(from: Date())
        let fileName = "Note \(dateString).txt"
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error creating temp file: \(error)")
            return fileURL // Return path anyway, though empty/failed
        }
    }
    /// Exports the current text to a file on the Desktop
    func exportToDesktop() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let dateString = formatter.string(from: Date())
        let fileName = "Quartz Note \(dateString).txt"
        
        // Get Desktop Directory safely
        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            print("Could not find Desktop directory")
            return
        }
        
        let fileURL = desktopURL.appendingPathComponent(fileName)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            // Optional: Play a system sound or give feedback (not implemented here to keep it minimal as requested)
        } catch {
            print("Error exporting to Desktop: \(error)")
        }
    }
}
