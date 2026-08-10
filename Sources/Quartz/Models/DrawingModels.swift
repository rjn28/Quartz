import SwiftUI

enum ShapeType: String, CaseIterable, Identifiable, Codable, Sendable {
    case line = "Line"
    case circle = "Circle"
    case square = "Square"
    case rectangle = "Rectangle"
    case text = "Text"

    var id: Self { self }

    var iconName: String {
        switch self {
        case .line: "line.diagonal"
        case .circle: "circle"
        case .square: "square"
        case .rectangle: "rectangle"
        case .text: "textformat"
        }
    }
}

enum DrawingPaletteColor: String, CaseIterable, Identifiable, Sendable {
    case white = "White"
    case black = "Black"
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"

    var id: Self { self }

    var color: Color {
        switch self {
        case .white: .white
        case .black: .black
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .blue: .blue
        case .purple: .purple
        case .pink: .pink
        }
    }
}

private struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(_ color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.sRGB) ?? .black
        red = Double(nsColor.redComponent)
        green = Double(nsColor.greenComponent)
        blue = Double(nsColor.blueComponent)
        opacity = Double(nsColor.alphaComponent)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

private struct CodablePoint: Codable {
    let x: Double
    let y: Double

    init(_ point: CGPoint) {
        x = point.x
        y = point.y
    }

    var point: CGPoint { CGPoint(x: x, y: y) }
}

struct DrawableShape: Identifiable, Codable {
    let id: UUID
    let type: ShapeType
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: Color
    var strokeWidth: CGFloat
    var text: String?

    var rect: CGRect {
        CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }

    var squareRect: CGRect {
        let deltaX = endPoint.x - startPoint.x
        let deltaY = endPoint.y - startPoint.y
        let size = min(abs(deltaX), abs(deltaY))
        return CGRect(
            x: deltaX < 0 ? startPoint.x - size : startPoint.x,
            y: deltaY < 0 ? startPoint.y - size : startPoint.y,
            width: size,
            height: size
        )
    }

    init(
        id: UUID = UUID(),
        type: ShapeType,
        startPoint: CGPoint,
        endPoint: CGPoint,
        color: Color,
        strokeWidth: CGFloat,
        text: String? = nil
    ) {
        self.id = id
        self.type = type
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.strokeWidth = strokeWidth
        self.text = text
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case startPoint
        case endPoint
        case color
        case strokeWidth
        case text
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
}
