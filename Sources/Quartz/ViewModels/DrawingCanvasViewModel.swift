import Combine
import SwiftUI
import os

@MainActor
final class DrawingCanvasViewModel: ObservableObject {
    @Published private(set) var shapes: [DrawableShape] = []
    @Published private(set) var currentShape: DrawableShape?
    @Published private(set) var redoShapes: [DrawableShape] = []
    @Published private(set) var canvasLoadError: String?
    @Published var selectedTool: ShapeType = .line
    @Published var selectedColor: DrawingPaletteColor = .blue
    @Published var strokeWidth: CGFloat = 2
    @Published var isEditingText = false
    @Published var textInputPosition = CGPoint.zero
    @Published var currentText = ""

    let noteID: UUID

    var canUndo: Bool { !shapes.isEmpty }
    var canRedo: Bool { !redoShapes.isEmpty }
    var canClear: Bool { !shapes.isEmpty || canvasLoadError != nil }

    private let noteLibrary: QuartzNoteLibrary
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.rjn28.Quartz", category: "Canvas")

    init(noteID: UUID, noteLibrary: QuartzNoteLibrary = .shared) {
        self.noteID = noteID
        self.noteLibrary = noteLibrary
        loadShapes()
        setUpAutoSave()
    }

    func startShape(at point: CGPoint) {
        if selectedTool == .text {
            textInputPosition = point
            isEditingText = true
            currentText = ""
            return
        }

        currentShape = DrawableShape(
            type: selectedTool,
            startPoint: point,
            endPoint: point,
            color: selectedColor.color,
            strokeWidth: strokeWidth
        )
    }

    func updateShape(to point: CGPoint) {
        guard selectedTool != .text else { return }
        currentShape?.endPoint = point
    }

    func endShape(at point: CGPoint) {
        guard selectedTool != .text else { return }
        currentShape?.endPoint = point

        if var shape = currentShape {
            applyDefaultSizeIfNeeded(to: &shape, at: point)
            shapes.append(shape)
            redoShapes.removeAll()
            canvasLoadError = nil
        }

        currentShape = nil
    }

    func addText() {
        guard !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            cancelTextEditing()
            return
        }

        shapes.append(
            DrawableShape(
                type: .text,
                startPoint: textInputPosition,
                endPoint: textInputPosition,
                color: selectedColor.color,
                strokeWidth: strokeWidth,
                text: currentText
            )
        )
        redoShapes.removeAll()
        canvasLoadError = nil
        cancelTextEditing()
    }

    func cancelTextEditing() {
        isEditingText = false
        currentText = ""
    }

    func undo() {
        guard let shape = shapes.popLast() else { return }
        redoShapes.append(shape)
    }

    func redo() {
        guard let shape = redoShapes.popLast() else { return }
        shapes.append(shape)
    }

    func clearCanvas() {
        shapes.removeAll()
        redoShapes.removeAll()
        currentShape = nil
        canvasLoadError = nil
        cancelTextEditing()
        noteLibrary.saveCanvasData(nil, for: noteID)
    }

    func flush() {
        saveShapes()
    }

    private func setUpAutoSave() {
        $shapes
            .dropFirst()
            .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.saveShapes() }
            .store(in: &cancellables)
    }

    private func saveShapes() {
        guard !shapes.isEmpty else {
            noteLibrary.saveCanvasData(nil, for: noteID)
            return
        }

        do {
            noteLibrary.saveCanvasData(try JSONEncoder().encode(shapes), for: noteID)
        } catch {
            logger.error("Unable to encode canvas: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func loadShapes() {
        guard let data = noteLibrary.canvasData(for: noteID) else { return }

        do {
            shapes = try JSONDecoder().decode([DrawableShape].self, from: data)
        } catch {
            canvasLoadError = "The saved canvas could not be read. You can reset it and continue."
            logger.error("Unable to decode canvas: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func applyDefaultSizeIfNeeded(to shape: inout DrawableShape, at point: CGPoint) {
        let width = abs(shape.endPoint.x - shape.startPoint.x)
        let height = abs(shape.endPoint.y - shape.startPoint.y)
        let defaultSize: CGFloat = 50
        let minimumSize: CGFloat = 5

        guard width < minimumSize, height < minimumSize else { return }

        switch shape.type {
        case .line:
            shape.endPoint = CGPoint(
                x: shape.startPoint.x + defaultSize,
                y: shape.startPoint.y + defaultSize
            )
        case .circle, .square:
            shape.startPoint = CGPoint(x: point.x - defaultSize / 2, y: point.y - defaultSize / 2)
            shape.endPoint = CGPoint(x: point.x + defaultSize / 2, y: point.y + defaultSize / 2)
        case .rectangle:
            shape.startPoint = CGPoint(x: point.x - defaultSize, y: point.y - defaultSize / 2)
            shape.endPoint = CGPoint(x: point.x + defaultSize, y: point.y + defaultSize / 2)
        case .text:
            break
        }
    }
}
