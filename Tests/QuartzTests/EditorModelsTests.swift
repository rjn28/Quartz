import XCTest
@testable import Quartz

final class EditorModelsTests: XCTestCase {
    func testEditorModeAlwaysRepresentsOneLayout() {
        XCTAssertEqual(EditorMode(isPreviewMode: false, isSplitView: false), .editor)
        XCTAssertEqual(EditorMode(isPreviewMode: true, isSplitView: false), .preview)
        XCTAssertEqual(EditorMode(isPreviewMode: false, isSplitView: true), .split)
        XCTAssertEqual(EditorMode(isPreviewMode: true, isSplitView: true), .split)
        XCTAssertTrue(EditorMode.preview.isPreviewMode)
        XCTAssertFalse(EditorMode.preview.isSplitView)
    }

    func testTextStatisticsHandleWhitespaceUnicodeAndLines() {
        let statistics = TextStatistics(text: "Hello\tQuartz\n👋 world")

        XCTAssertEqual(statistics.wordCount, 4)
        XCTAssertEqual(statistics.characterCountWithSpaces, 20)
        XCTAssertEqual(statistics.characterCountWithoutSpaces, 17)
        XCTAssertEqual(statistics.lineCount, 2)
    }

    func testReadingTimeRoundsUp() {
        XCTAssertEqual(TextStatistics(text: "").readingMinutes, 0)
        XCTAssertEqual(TextStatistics(text: repeatedWords(200)).readingMinutes, 1)
        XCTAssertEqual(TextStatistics(text: repeatedWords(201)).readingMinutes, 2)
        XCTAssertEqual(TextStatistics(text: repeatedWords(400)).readingMinutes, 2)
    }

    func testLabelsMatchSelectedStatistic() {
        let statistics = TextStatistics(text: "one two\nthree")

        XCTAssertEqual(statistics.label(for: .words), "3 words")
        XCTAssertEqual(statistics.label(for: .lines), "2 lines")
        XCTAssertEqual(statistics.label(for: .readingTime), "1 min read")
    }

    func testNoteTitleUsesFirstNonEmptyLineAndMenuTitleIsBounded() {
        let note = QuartzNote(
            updatedAt: Date(timeIntervalSince1970: 0),
            text: "\n  A deliberately long title that exceeds forty characters by far\nBody"
        )

        XCTAssertEqual(note.title.count, 40)
        XCTAssertLessThanOrEqual(note.menuTitle.count, 30)
    }

    func testNoteContentIgnoresWhitespaceAndEmptyCanvasData() {
        XCTAssertFalse(QuartzNote(text: "  \n", canvasData: Data()).hasContent)
        XCTAssertTrue(QuartzNote(text: "Quartz").hasContent)
        XCTAssertTrue(QuartzNote(canvasData: Data([0x01])).hasContent)
    }

    private func repeatedWords(_ count: Int) -> String {
        Array(repeating: "word", count: count).joined(separator: " ")
    }
}
