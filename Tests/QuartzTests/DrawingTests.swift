import AppKit
import XCTest
@testable import Quartz

@MainActor
final class DrawingTests: XCTestCase {
    func testSquareRectStaysAnchoredForEveryDragDirection() {
        assertSquare(end: CGPoint(x: 150, y: 120), expectedOrigin: CGPoint(x: 100, y: 100))
        assertSquare(end: CGPoint(x: 50, y: 120), expectedOrigin: CGPoint(x: 80, y: 100))
        assertSquare(end: CGPoint(x: 150, y: 80), expectedOrigin: CGPoint(x: 100, y: 80))
        assertSquare(end: CGPoint(x: 50, y: 80), expectedOrigin: CGPoint(x: 80, y: 80))
    }

    func testShapeCodableRoundTripPreservesDrawingData() throws {
        let original = DrawableShape(
            type: .text,
            startPoint: CGPoint(x: 12, y: 34),
            endPoint: CGPoint(x: 56, y: 78),
            color: .purple,
            strokeWidth: 4,
            text: "Quartz"
        )

        let decoded = try JSONDecoder().decode(
            DrawableShape.self,
            from: JSONEncoder().encode(original)
        )

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.type, .text)
        XCTAssertEqual(decoded.startPoint, original.startPoint)
        XCTAssertEqual(decoded.endPoint, original.endPoint)
        XCTAssertEqual(decoded.strokeWidth, 4)
        XCTAssertEqual(decoded.text, "Quartz")
        let color = try XCTUnwrap(NSColor(decoded.color).usingColorSpace(.sRGB))
        XCTAssertEqual(color.alphaComponent, 1, accuracy: 0.001)
    }

    func testCanvasFlushPersistsWithoutWaitingForDebounce() throws {
        let context = try makeDrawingContext()
        defer { context.cleanup() }
        let noteID = UUID()
        let library = QuartzNoteLibrary(defaults: context.defaults)
        let viewModel = DrawingCanvasViewModel(noteID: noteID, noteLibrary: library)

        viewModel.startShape(at: .zero)
        viewModel.endShape(at: CGPoint(x: 30, y: 40))
        viewModel.flush()

        let reloaded = DrawingCanvasViewModel(
            noteID: noteID,
            noteLibrary: QuartzNoteLibrary(defaults: context.defaults)
        )
        XCTAssertEqual(reloaded.shapes.count, 1)
    }

    func testUndoAndRedoPreserveShape() throws {
        let context = try makeDrawingContext()
        defer { context.cleanup() }
        let library = QuartzNoteLibrary(defaults: context.defaults)
        let viewModel = DrawingCanvasViewModel(noteID: UUID(), noteLibrary: library)
        viewModel.startShape(at: .zero)
        viewModel.endShape(at: CGPoint(x: 20, y: 20))

        viewModel.undo()
        XCTAssertFalse(viewModel.canUndo)
        XCTAssertTrue(viewModel.canRedo)

        viewModel.redo()
        XCTAssertTrue(viewModel.canUndo)
        XCTAssertFalse(viewModel.canRedo)
    }

    func testCorruptCanvasCanBeReset() throws {
        let context = try makeDrawingContext()
        defer { context.cleanup() }
        let noteID = UUID()
        let library = QuartzNoteLibrary(defaults: context.defaults)
        library.saveCanvasData(Data("invalid".utf8), for: noteID)
        let viewModel = DrawingCanvasViewModel(noteID: noteID, noteLibrary: library)

        XCTAssertNotNil(viewModel.canvasLoadError)
        XCTAssertTrue(viewModel.canClear)

        viewModel.clearCanvas()
        XCTAssertNil(viewModel.canvasLoadError)
        XCTAssertTrue(library.notes.isEmpty)
    }

    private func assertSquare(end: CGPoint, expectedOrigin: CGPoint) {
        let shape = DrawableShape(
            type: .square,
            startPoint: CGPoint(x: 100, y: 100),
            endPoint: end,
            color: .blue,
            strokeWidth: 2
        )

        XCTAssertEqual(shape.squareRect.origin.x, expectedOrigin.x, accuracy: 0.001)
        XCTAssertEqual(shape.squareRect.origin.y, expectedOrigin.y, accuracy: 0.001)
        XCTAssertEqual(shape.squareRect.width, 20, accuracy: 0.001)
        XCTAssertEqual(shape.squareRect.height, 20, accuracy: 0.001)
    }

    private func makeDrawingContext() throws -> TestDefaultsContext {
        let suiteName = "QuartzDrawingTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return TestDefaultsContext(defaults: defaults, suiteName: suiteName)
    }
}
