import SwiftUI
import Combine

// MARK: - Shape Types

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

// MARK: - Codable Helpers

struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(_ color: Color) {
        // Convert SwiftUI Color to RGB components
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

// MARK: - Drawable Shape Model

struct DrawableShape: Identifiable, Codable {
    let id: UUID
    let type: ShapeType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: Color
    var strokeWidth: CGFloat
    var text: String?
    
    // Custom coding keys
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
        let codableStart = try container.decode(CodablePoint.self, forKey: .startPoint)
        startPoint = codableStart.point
        let codableEnd = try container.decode(CodablePoint.self, forKey: .endPoint)
        endPoint = codableEnd.point
        let codableColor = try container.decode(CodableColor.self, forKey: .color)
        color = codableColor.color
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
    
    // Computed property for rectangle from two points
    var rect: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
    
    // For square, use the smaller dimension
    var squareRect: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let size = min(abs(endPoint.x - startPoint.x), abs(endPoint.y - startPoint.y))
        return CGRect(x: minX, y: minY, width: size, height: size)
    }
}

// MARK: - Drawing Canvas ViewModel

class DrawingCanvasViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var shapes: [DrawableShape] = []
    @Published var currentShape: DrawableShape?
    @Published var selectedTool: ShapeType = .line
    @Published var strokeColor: Color = .primary
    @Published var strokeWidth: CGFloat = 2.0
    
    // Text input state
    @Published var isEditingText: Bool = false
    @Published var textInputPosition: CGPoint = .zero
    @Published var currentText: String = ""
    
    // MARK: - Private Properties
    private let shapesKey = "Quartz_canvas_shapes"
    private var cancellables = Set<AnyCancellable>()
    
    // Available colors for quick selection
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
    
    // MARK: - Initialization
    
    init() {
        loadShapes()
        setupAutoSave()
    }
    
    // MARK: - Persistence
    
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
        do {
            let data = try JSONEncoder().encode(shapes)
            UserDefaults.standard.set(data, forKey: shapesKey)
        } catch {
            print("Error saving shapes: \(error)")
        }
    }
    
    private func loadShapes() {
        guard let data = UserDefaults.standard.data(forKey: shapesKey) else { return }
        do {
            shapes = try JSONDecoder().decode([DrawableShape].self, from: data)
        } catch {
            print("Error loading shapes: \(error)")
        }
    }
    
    // MARK: - Methods

    
    /// Start drawing a new shape
    func startShape(at point: CGPoint) {
        if selectedTool == .text {
            // For text, show input at tap location
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
    
    /// Update the current shape while dragging
    func updateShape(to point: CGPoint) {
        guard selectedTool != .text else { return }
        currentShape?.endPoint = point
    }
    
    /// Finalize and add the current shape
    func endShape(at point: CGPoint) {
        guard selectedTool != .text else { return }
        currentShape?.endPoint = point
        
        if var shape = currentShape {
            let width = abs(shape.endPoint.x - shape.startPoint.x)
            let height = abs(shape.endPoint.y - shape.startPoint.y)
            
            // If it's a simple click (no drag), create a default sized shape
            let defaultSize: CGFloat = 50
            let minSize: CGFloat = 5
            
            if width < minSize && height < minSize {
                // Simple click - create default sized shape
                switch shape.type {
                case .line:
                    // Create a diagonal line
                    shape.endPoint = CGPoint(
                        x: shape.startPoint.x + defaultSize,
                        y: shape.startPoint.y + defaultSize
                    )
                case .circle, .square:
                    // Create centered shape
                    shape.startPoint = CGPoint(
                        x: point.x - defaultSize / 2,
                        y: point.y - defaultSize / 2
                    )
                    shape.endPoint = CGPoint(
                        x: point.x + defaultSize / 2,
                        y: point.y + defaultSize / 2
                    )
                case .rectangle:
                    // Create centered rectangle (wider than tall)
                    shape.startPoint = CGPoint(
                        x: point.x - defaultSize,
                        y: point.y - defaultSize / 2
                    )
                    shape.endPoint = CGPoint(
                        x: point.x + defaultSize,
                        y: point.y + defaultSize / 2
                    )
                case .text:
                    break
                }
            }
            
            shapes.append(shape)
        }
        currentShape = nil
    }
    
    /// Add text at the current position
    func addText() {
        guard !currentText.isEmpty else {
            isEditingText = false
            return
        }
        
        let textShape = DrawableShape(
            type: .text,
            startPoint: textInputPosition,
            endPoint: textInputPosition,
            color: strokeColor,
            strokeWidth: strokeWidth,
            text: currentText
        )
        shapes.append(textShape)
        isEditingText = false
        currentText = ""
    }
    
    /// Remove the last shape (undo)
    func undo() {
        guard !shapes.isEmpty else { return }
        shapes.removeLast()
    }
    
    /// Clear all shapes
    func clearCanvas() {
        shapes.removeAll()
        currentShape = nil
        isEditingText = false
        currentText = ""
    }
}
