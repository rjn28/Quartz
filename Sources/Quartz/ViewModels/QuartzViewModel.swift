import Combine
import SwiftUI

@MainActor
final class QuartzViewModel: ObservableObject {
    @Published var text = ""
    @Published var isDarkMode = true
    @Published var selectedStat: TextStatType = .words
    @Published var fontSize: QuartzFontSize = .normal
    @Published var editorMode: EditorMode = .editor

    let noteID: UUID

    var statText: String {
        TextStatistics(text: text).label(for: selectedStat)
    }

    private let noteLibrary: QuartzNoteLibrary
    private let exportService: NoteExportService
    private var cancellables = Set<AnyCancellable>()

    init(
        noteID: UUID,
        noteLibrary: QuartzNoteLibrary = .shared,
        exportService: NoteExportService = NoteExportService()
    ) {
        self.noteID = noteID
        self.noteLibrary = noteLibrary
        self.exportService = exportService
        loadState()
        setUpAutoSave()
    }

    func toggleTheme() {
        isDarkMode.toggle()
    }

    func clearText() {
        text = ""
    }

    func flush() {
        saveCurrentState()
    }

    func createTemporaryTextFile() throws -> URL {
        try exportService.createTemporaryTextFile(text: text)
    }

    @discardableResult
    func exportTextToDesktop() throws -> URL {
        try exportService.exportTextToDesktop(text: text)
    }

    private func setUpAutoSave() {
        $text
            .dropFirst()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveCurrentState()
            }
            .store(in: &cancellables)

        $isDarkMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.saveCurrentState() }
            .store(in: &cancellables)

        $selectedStat
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.saveCurrentState() }
            .store(in: &cancellables)

        $fontSize
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.saveCurrentState() }
            .store(in: &cancellables)

        $editorMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in self?.saveCurrentState() }
            .store(in: &cancellables)
    }

    private func loadState() {
        let note = noteLibrary.noteSnapshot(for: noteID)
        text = note.text
        isDarkMode = note.isDarkMode
        selectedStat = TextStatType(rawValue: note.selectedStatRawValue) ?? .words
        fontSize = QuartzFontSize(rawValue: note.fontSizeRawValue) ?? .normal
        editorMode = EditorMode(
            isPreviewMode: note.isPreviewMode,
            isSplitView: note.isSplitView
        )
    }

    private func saveCurrentState() {
        noteLibrary.saveEditorState(
            noteID: noteID,
            text: text,
            isDarkMode: isDarkMode,
            selectedStat: selectedStat,
            fontSize: fontSize,
            editorMode: editorMode
        )
    }
}
