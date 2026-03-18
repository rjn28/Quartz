import SwiftUI
import Combine

enum ShapeType: String, CaseIterable, Identifiable, Codable {
    case line = "Line"
    case circle = "Circle"
    case square = "Square"
    case rectangle = "Rectangle"
    case text = "Text"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .line: return "line.diagonal"
        case .circle: return "circle"
        case .square: return "square"
        case .rectangle: return "rectangle"
        case .text: return "textformat"
        }
    }
}

struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(_ color: Color) {
        let nsColor = NSColor(color)
        let converted = nsColor.usingColorSpace(.sRGB) ?? nsColor
        self.red = Double(converted.redComponent)
        self.green = Double(converted.greenComponent)
        self.blue = Double(converted.blueComponent)
        self.opacity = Double(converted.alphaComponent)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

struct CodablePoint: Codable {
    let x: Double
    let y: Double

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }

    var point: CGPoint {
        CGPoint(x: x, y: y)
    }
}

struct DrawableShape: Identifiable, Codable {
    let id: UUID
    let type: ShapeType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: Color
    var strokeWidth: CGFloat
    var text: String?

    enum CodingKeys: String, CodingKey {
        case id, type, startPoint, endPoint, color, strokeWidth, text
    }

    init(type: ShapeType, startPoint: CGPoint, endPoint: CGPoint, color: Color, strokeWidth: CGFloat, text: String? = nil) {
        self.id = UUID()
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.strokeWidth = strokeWidth
        self.text = text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(ShapeType.self, forKey: .type)
        startPoint = try container.decode(CodablePoint.self, forKey: .startPoint).point
        endPoint = try container.decode(CodablePoint.self, forKey: .endPoint).point
        color = try container.decode(CodableColor.self, forKey: .color).color
        strokeWidth = try container.decode(CGFloat.self, forKey: .strokeWidth)
        text = try container.decodeIfPresent(String.self, forKey: .text)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(CodablePoint(startPoint), forKey: .startPoint)
        try container.encode(CodablePoint(endPoint), forKey: .endPoint)
        try container.encode(CodableColor(color), forKey: .color)
        try container.encode(strokeWidth, forKey: .strokeWidth)
        try container.encodeIfPresent(text, forKey: .text)
    }

    var rect: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }

    var squareRect: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let size = min(abs(endPoint.x - startPoint.x), abs(endPoint.y - startPoint.y))
        return CGRect(x: minX, y: minY, width: size, height: size)
    }
}

@MainActor
final class DrawingCanvasViewModel: ObservableObject {
    @Published var shapes: [DrawableShape] = []
    @Published var currentShape: DrawableShape?
    @Published var selectedTool: ShapeType = .line
    @Published var strokeColor: Color = .primary
    @Published var strokeWidth: CGFloat = 2.0
    @Published var isEditingText: Bool = false
    @Published var textInputPosition: CGPoint = .zero
    @Published var currentText: String = ""

    let noteID: UUID

    private var cancellables = Set<AnyCancellable>()

    let availableColors: [Color] = [
        .primary,
        .red,
        .orange,
        .yellow,
        .green,
        .blue,
        .purple,
        .pink
    ]

    init(noteID: UUID) {
        self.noteID = noteID
        loadShapes()
        setupAutoSave()
    }

    private func setupAutoSave() {
        $shapes
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveShapes()
            }
            .store(in: &cancellables)
    }

    private func saveShapes() {
        guard !shapes.isEmpty else {
            QuartzNoteLibrary.shared.saveCanvasData(nil, for: noteID)
            return
        }

        do {
            let data = try JSONEncoder().encode(shapes)
            QuartzNoteLibrary.shared.saveCanvasData(data, for: noteID)
        } catch {
            print("Error saving shapes: \(error)")
        }
    }

    private func loadShapes() {
        guard let data = QuartzNoteLibrary.shared.canvasData(for: noteID) else { return }

        do {
            shapes = try JSONDecoder().decode([DrawableShape].self, from: data)
        } catch {
            print("Error loading shapes: \(error)")
        }
    }

    func startShape(at point: CGPoint) {
        if selectedTool == .text {
            textInputPosition = point
            isEditingText = true
            currentText = ""
        } else {
            currentShape = DrawableShape(
                type: selectedTool,
                startPoint: point,
                endPoint: point,
                color: strokeColor,
                strokeWidth: strokeWidth
            )
        }
    }

    func updateShape(to point: CGPoint) {
        guard selectedTool != .text else { return }
        currentShape?.endPoint = point
    }

    func endShape(at point: CGPoint) {
        guard selectedTool != .text else { return }
        currentShape?.endPoint = point

        if var shape = currentShape {
            let width = abs(shape.endPoint.x - shape.startPoint.x)
            let height = abs(shape.endPoint.y - shape.startPoint.y)
            let defaultSize: CGFloat = 50
            let minSize: CGFloat = 5

            if width < minSize && height < minSize {
                switch shape.type {
                case .line:
                    shape.endPoint = CGPoint(x: shape.startPoint.x + defaultSize, y: shape.startPoint.y + defaultSize)
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

            shapes.append(shape)
        }

        currentShape = nil
    }

    func addText() {
        guard !currentText.isEmpty else {
            isEditingText = false
            return
        }

        shapes.append(
            DrawableShape(
                type: .text,
                startPoint: textInputPosition,
                endPoint: textInputPosition,
                color: strokeColor,
                strokeWidth: strokeWidth,
                text: currentText
            )
        )

        isEditingText = false
        currentText = ""
    }

    func undo() {
        guard !shapes.isEmpty else { return }
        shapes.removeLast()
    }

    func clearCanvas() {
        shapes.removeAll()
        currentShape = nil
        isEditingText = false
        currentText = ""
        QuartzNoteLibrary.shared.saveCanvasData(nil, for: noteID)
    }
}
