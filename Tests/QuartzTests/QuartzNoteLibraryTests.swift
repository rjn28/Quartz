import XCTest
@testable import Quartz

@MainActor
final class QuartzNoteLibraryTests: XCTestCase {
    func testRoutesDeduplicateSavedNotesButKeepNewNotesUnique() throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let library = QuartzNoteLibrary(defaults: context.defaults)
        let noteID = UUID()

        XCTAssertEqual(library.makeRoute(for: noteID), library.makeRoute(for: noteID))
        XCTAssertNotEqual(library.makeNewRoute(), library.makeNewRoute())
    }

    func testEditorStatePersistsAndEmptyTextRemovesTextOnlyNote() throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let noteID = UUID()
        let library = QuartzNoteLibrary(defaults: context.defaults)

        library.saveEditorState(
            noteID: noteID,
            text: "Persist me",
            isDarkMode: false,
            selectedStat: .lines,
            fontSize: .large,
            editorMode: .split
        )

        let reloaded = QuartzNoteLibrary(defaults: context.defaults)
        let note = try XCTUnwrap(reloaded.notes.first)
        XCTAssertEqual(note.id, noteID)
        XCTAssertEqual(note.text, "Persist me")
        XCTAssertFalse(note.isDarkMode)
        XCTAssertTrue(note.isSplitView)
        XCTAssertFalse(note.isPreviewMode)

        reloaded.saveEditorState(
            noteID: noteID,
            text: "   ",
            isDarkMode: false,
            selectedStat: .lines,
            fontSize: .large,
            editorMode: .split
        )
        XCTAssertTrue(reloaded.notes.isEmpty)
    }

    func testCanvasOnlyNoteSurvivesEmptyText() throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let noteID = UUID()
        let library = QuartzNoteLibrary(defaults: context.defaults)

        library.saveCanvasData(Data([1, 2, 3]), for: noteID)
        library.saveEditorState(
            noteID: noteID,
            text: "",
            isDarkMode: true,
            selectedStat: .words,
            fontSize: .normal,
            editorMode: .editor
        )

        XCTAssertEqual(library.notes.count, 1)
        XCTAssertEqual(library.notes[0].canvasData, Data([1, 2, 3]))
    }

    func testCorruptLibraryIsQuarantinedBeforeNewWrites() throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let corruptData = Data("not-json".utf8)
        context.defaults.set(corruptData, forKey: QuartzNoteLibrary.StorageKeys.notes)

        let library = QuartzNoteLibrary(defaults: context.defaults)

        XCTAssertTrue(library.notes.isEmpty)
        XCTAssertEqual(
            context.defaults.data(forKey: QuartzNoteLibrary.StorageKeys.corruptedNotesBackup),
            corruptData
        )
    }

    func testDirectV12MigrationCombinesLegacyTextAndCanvas() throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let shapeData = try JSONEncoder().encode([sampleShape])
        context.defaults.set("Legacy text", forKey: QuartzNoteLibrary.StorageKeys.legacyText)
        context.defaults.set(shapeData, forKey: QuartzNoteLibrary.StorageKeys.legacyCanvas)

        let library = QuartzNoteLibrary(defaults: context.defaults)

        let note = try XCTUnwrap(library.notes.first)
        XCTAssertEqual(note.text, "Legacy text")
        XCTAssertEqual(note.canvasData, shapeData)
        XCTAssertEqual(
            context.defaults.integer(forKey: QuartzNoteLibrary.StorageKeys.migrationVersion),
            2
        )
    }

    func testV2MigrationRepairsAStoreThatAlreadyRanV1() throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let existingNote = QuartzNote(text: "Legacy text")
        let shapeData = try JSONEncoder().encode([sampleShape])
        context.defaults.set(
            try JSONEncoder().encode([existingNote]),
            forKey: QuartzNoteLibrary.StorageKeys.notes
        )
        context.defaults.set(1, forKey: QuartzNoteLibrary.StorageKeys.migrationVersion)
        context.defaults.set("Legacy text", forKey: QuartzNoteLibrary.StorageKeys.legacyText)
        context.defaults.set(shapeData, forKey: QuartzNoteLibrary.StorageKeys.legacyCanvas)

        let firstLoad = QuartzNoteLibrary(defaults: context.defaults)
        let secondLoad = QuartzNoteLibrary(defaults: context.defaults)

        XCTAssertEqual(firstLoad.notes.count, 1)
        XCTAssertEqual(firstLoad.notes[0].canvasData, shapeData)
        XCTAssertEqual(secondLoad.notes.count, 1, "The migration must be idempotent")
        XCTAssertEqual(secondLoad.notes[0].canvasData, shapeData)
    }

    func testLegacyPerWindowStateMigrates() throws {
        let context = try makeContext()
        defer { context.cleanup() }
        let noteID = UUID()
        let baseKey = "Quartz.window.\(noteID.uuidString)"
        context.defaults.set("Window text", forKey: "\(baseKey).text")
        context.defaults.set(false, forKey: "\(baseKey).darkMode")
        context.defaults.set(true, forKey: "\(baseKey).previewMode")

        let library = QuartzNoteLibrary(defaults: context.defaults)
        let note = try XCTUnwrap(library.notes.first)

        XCTAssertEqual(note.id, noteID)
        XCTAssertEqual(note.text, "Window text")
        XCTAssertFalse(note.isDarkMode)
        XCTAssertTrue(note.isPreviewMode)
    }

    private var sampleShape: DrawableShape {
        DrawableShape(
            type: .line,
            startPoint: .zero,
            endPoint: CGPoint(x: 10, y: 10),
            color: .blue,
            strokeWidth: 2
        )
    }

    private func makeContext() throws -> TestDefaultsContext {
        let suiteName = "QuartzTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return TestDefaultsContext(defaults: defaults, suiteName: suiteName)
    }
}
