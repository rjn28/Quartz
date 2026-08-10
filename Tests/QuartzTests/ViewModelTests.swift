import XCTest
@testable import Quartz

@MainActor
final class ViewModelTests: XCTestCase {
    func testEditorViewModelFlushesTextAndValidMode() throws {
        let suiteName = "QuartzViewModelTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let noteID = UUID()
        let library = QuartzNoteLibrary(defaults: defaults)
        let viewModel = QuartzViewModel(noteID: noteID, noteLibrary: library)

        viewModel.text = "Unsaved text"
        viewModel.editorMode = .preview
        viewModel.flush()

        let note = try XCTUnwrap(library.notes.first)
        XCTAssertEqual(note.text, "Unsaved text")
        XCTAssertTrue(note.isPreviewMode)
        XCTAssertFalse(note.isSplitView)
    }

    func testViewModelRestoresPersistedPreferences() throws {
        let suiteName = "QuartzRestoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let noteID = UUID()
        let library = QuartzNoteLibrary(defaults: defaults)
        library.saveEditorState(
            noteID: noteID,
            text: "Quartz",
            isDarkMode: false,
            selectedStat: .charactersNoSpaces,
            fontSize: .extraLarge,
            editorMode: .split
        )

        let viewModel = QuartzViewModel(noteID: noteID, noteLibrary: library)

        XCTAssertEqual(viewModel.text, "Quartz")
        XCTAssertFalse(viewModel.isDarkMode)
        XCTAssertEqual(viewModel.selectedStat, .charactersNoSpaces)
        XCTAssertEqual(viewModel.fontSize, .extraLarge)
        XCTAssertEqual(viewModel.editorMode, .split)
    }
}
