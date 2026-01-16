import SwiftUI

struct DrawingCanvasView: View {
    @Binding var isPresented: Bool
    let isDarkMode: Bool
    
    @StateObject private var viewModel = DrawingCanvasViewModel()
    @State private var showClearConfirmation = false
    
    var body: some View {
        ZStack {
            // MARK: - Background
            (isDarkMode ? Color(red: 0.08, green: 0.08, blue: 0.08) : Color(white: 0.98))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Top Bar
                topBar
                
                // MARK: - Canvas Area
                canvasArea
                
                // MARK: - Bottom Toolbar
                bottomToolbar
            }
            
            // MARK: - Text Input Overlay
            if viewModel.isEditingText {
                textInputOverlay
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Undo Button
            Button(action: {
                viewModel.undo()
            }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.shapes.isEmpty)
            .opacity(viewModel.shapes.isEmpty ? 0.3 : 1)
            .help("Undo")
            
            // Clear Button
            Button(action: {
                showClearConfirmation = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.shapes.isEmpty)
            .opacity(viewModel.shapes.isEmpty ? 0.3 : 1)
            .help("Clear Canvas")
            .confirmationDialog("Clear Canvas?", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    viewModel.clearCanvas()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            
            Spacer()
            
            // Title
            Text("Canvas")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Close Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Close Canvas")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Canvas Area
    
    private var canvasArea: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw all completed shapes
                for shape in viewModel.shapes {
                    drawShape(shape, in: &context)
                }
                
                // Draw current shape being drawn
                if let currentShape = viewModel.currentShape {
                    drawShape(currentShape, in: &context)
                }
            }
            .background(isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.12) : .white)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if viewModel.currentShape == nil {
                            viewModel.startShape(at: value.startLocation)
                        }
                        viewModel.updateShape(to: value.location)
                    }
                    .onEnded { value in
                        viewModel.endShape(at: value.location)
                    }
            )
            .onTapGesture { location in
                if viewModel.selectedTool == .text {
                    viewModel.startShape(at: location)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Draw Shape Helper
    
    private func drawShape(_ shape: DrawableShape, in context: inout GraphicsContext) {
        let strokeStyle = StrokeStyle(lineWidth: shape.strokeWidth, lineCap: .round, lineJoin: .round)
        
        switch shape.type {
        case .line:
            var path = Path()
            path.move(to: shape.startPoint)
            path.addLine(to: shape.endPoint)
            context.stroke(path, with: .color(shape.color), style: strokeStyle)
            
        case .circle:
            let rect = shape.rect
            let diameter = min(rect.width, rect.height)
            let circleRect = CGRect(
                x: rect.midX - diameter / 2,
                y: rect.midY - diameter / 2,
                width: diameter,
                height: diameter
            )
            let path = Circle().path(in: circleRect)
            context.stroke(path, with: .color(shape.color), style: strokeStyle)
            
        case .square:
            let path = Rectangle().path(in: shape.squareRect)
            context.stroke(path, with: .color(shape.color), style: strokeStyle)
            
        case .rectangle:
            let path = Rectangle().path(in: shape.rect)
            context.stroke(path, with: .color(shape.color), style: strokeStyle)
            
        case .text:
            if let text = shape.text {
                let resolvedText = context.resolve(
                    Text(text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(shape.color)
                )
                context.draw(resolvedText, at: shape.startPoint, anchor: .topLeading)
            }
        }
    }
    
    // MARK: - Bottom Toolbar
    
    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            // Shape Tools
            ForEach(ShapeType.allCases) { tool in
                Button(action: {
                    viewModel.selectedTool = tool
                }) {
                    Image(systemName: tool.iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(viewModel.selectedTool == tool ? .white : .primary)
                        .frame(width: 36, height: 36)
                        .background(
                            viewModel.selectedTool == tool
                                ? Color.blue
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .help(tool.rawValue)
            }
            
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 24)
            
            // Color Picker
            HStack(spacing: 8) {
                ForEach(viewModel.availableColors, id: \.self) { color in
                    Button(action: {
                        viewModel.strokeColor = color
                    }) {
                        Circle()
                            .fill(color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(
                                        viewModel.strokeColor == color
                                            ? Color.white
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(
                                color: viewModel.strokeColor == color
                                    ? color.opacity(0.5)
                                    : .clear,
                                radius: 4
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 24)
            
            // Stroke Width
            Menu {
                Button("Thin (1pt)") { viewModel.strokeWidth = 1 }
                Button("Normal (2pt)") { viewModel.strokeWidth = 2 }
                Button("Medium (4pt)") { viewModel.strokeWidth = 4 }
                Button("Thick (6pt)") { viewModel.strokeWidth = 6 }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "lineweight")
                        .font(.system(size: 16, weight: .medium))
                    Text("\(Int(viewModel.strokeWidth))pt")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Text Input Overlay
    
    private var textInputOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.addText()
                }
            
            VStack(spacing: 12) {
                Text("Enter Text")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                TextField("Type here...", text: $viewModel.currentText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isDarkMode ? Color(white: 0.2) : Color(white: 0.95))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 250)
                    .onSubmit {
                        viewModel.addText()
                    }
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        viewModel.isEditingText = false
                        viewModel.currentText = ""
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    
                    Button("Add") {
                        viewModel.addText()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
            .padding(24)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
    }
}
