import SwiftUI

struct DrawingCanvasView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Binding var isPresented: Bool
    let isDarkMode: Bool
    let noteID: UUID

    @StateObject private var viewModel: DrawingCanvasViewModel
    @State private var showClearConfirmation = false
    @FocusState private var isTextFieldFocused: Bool

    init(isPresented: Binding<Bool>, isDarkMode: Bool, noteID: UUID) {
        _isPresented = isPresented
        self.isDarkMode = isDarkMode
        self.noteID = noteID
        _viewModel = StateObject(wrappedValue: DrawingCanvasViewModel(noteID: noteID))
    }

    var body: some View {
        ZStack {
            Color(nsColor: .textBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                if let message = viewModel.canvasLoadError {
                    canvasRecoveryBanner(message)
                }

                canvasArea
                bottomToolbar
            }

            if viewModel.isEditingText {
                textInputOverlay
            }
        }
        .onDisappear {
            viewModel.flush()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                viewModel.flush()
            }
        }
        .onChange(of: viewModel.isEditingText) { _, isEditing in
            if isEditing {
                isTextFieldFocused = true
            }
        }
        .confirmationDialog("Clear the canvas?", isPresented: $showClearConfirmation) {
            Button("Clear Canvas", role: .destructive) {
                viewModel.clearCanvas()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            canvasButton(
                systemName: "arrow.uturn.backward",
                label: "Undo",
                isEnabled: viewModel.canUndo,
                action: viewModel.undo
            )
            .keyboardShortcut("z", modifiers: .command)

            canvasButton(
                systemName: "arrow.uturn.forward",
                label: "Redo",
                isEnabled: viewModel.canRedo,
                action: viewModel.redo
            )
            .keyboardShortcut("z", modifiers: [.command, .shift])

            canvasButton(
                systemName: "trash",
                label: "Clear canvas",
                isEnabled: viewModel.canClear,
                role: .destructive,
                action: { showClearConfirmation = true }
            )

            Spacer()

            Text("Canvas")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            canvasButton(
                systemName: "xmark.circle.fill",
                label: "Close canvas"
            ) {
                viewModel.flush()
                isPresented = false
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func canvasRecoveryBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Spacer()
            Button("Reset Canvas", role: .destructive) {
                showClearConfirmation = true
            }
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.orange.opacity(0.1))
    }

    private var canvasArea: some View {
        Canvas { context, _ in
            for shape in viewModel.shapes {
                draw(shape, in: &context)
            }
            if let currentShape = viewModel.currentShape {
                draw(currentShape, in: &context)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard viewModel.selectedTool != .text else { return }
                    if viewModel.currentShape == nil {
                        viewModel.startShape(at: value.startLocation)
                    }
                    viewModel.updateShape(to: value.location)
                }
                .onEnded { value in
                    guard viewModel.selectedTool != .text else { return }
                    viewModel.endShape(at: value.location)
                }
        )
        .onTapGesture { location in
            guard viewModel.selectedTool == .text else { return }
            viewModel.startShape(at: location)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.primary.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityLabel("Drawing canvas")
        .accessibilityHint("Choose a tool below, then drag on the canvas to draw")
    }

    private var bottomToolbar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(ShapeType.allCases) { tool in
                    Button {
                        viewModel.selectedTool = tool
                    } label: {
                        Image(systemName: tool.iconName)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(viewModel.selectedTool == tool ? .white : .primary)
                            .frame(width: 34, height: 34)
                            .background(
                                viewModel.selectedTool == tool ? Color.accentColor : .clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(tool.rawValue)
                    .accessibilityLabel("\(tool.rawValue) tool")
                    .accessibilityAddTraits(viewModel.selectedTool == tool ? .isSelected : [])
                }

                toolbarDivider

                ForEach(DrawingPaletteColor.allCases) { paletteColor in
                    Button {
                        viewModel.selectedColor = paletteColor
                    } label: {
                        Circle()
                            .fill(paletteColor.color)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(
                                        viewModel.selectedColor == paletteColor ?
                                            Color.accentColor : Color.primary.opacity(0.2),
                                        lineWidth: viewModel.selectedColor == paletteColor ? 3 : 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .help(paletteColor.rawValue)
                    .accessibilityLabel("\(paletteColor.rawValue) stroke")
                    .accessibilityAddTraits(
                        viewModel.selectedColor == paletteColor ? .isSelected : []
                    )
                }

                toolbarDivider

                strokeWidthMenu
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.primary.opacity(0.12), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private var toolbarDivider: some View {
        Rectangle()
            .fill(.primary.opacity(0.16))
            .frame(width: 1, height: 24)
            .accessibilityHidden(true)
    }

    private var strokeWidthMenu: some View {
        Menu {
            Button("Thin (1 pt)") { viewModel.strokeWidth = 1 }
            Button("Normal (2 pt)") { viewModel.strokeWidth = 2 }
            Button("Medium (4 pt)") { viewModel.strokeWidth = 4 }
            Button("Thick (6 pt)") { viewModel.strokeWidth = 6 }
        } label: {
            Label("\(Int(viewModel.strokeWidth)) pt", systemImage: "lineweight")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        .menuStyle(.borderlessButton)
        .accessibilityLabel("Stroke width")
        .accessibilityValue("\(Int(viewModel.strokeWidth)) points")
    }

    private var textInputOverlay: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: viewModel.cancelTextEditing)

            VStack(spacing: 14) {
                Text("Add Text")
                    .font(.headline)

                TextField("Text", text: $viewModel.currentText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
                    .focused($isTextFieldFocused)
                    .onSubmit(viewModel.addText)

                HStack(spacing: 14) {
                    Button("Cancel", action: viewModel.cancelTextEditing)
                        .keyboardShortcut(.cancelAction)
                    Button("Add", action: viewModel.addText)
                        .keyboardShortcut(.defaultAction)
                        .disabled(
                            viewModel.currentText
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .isEmpty
                        )
                }
            }
            .padding(24)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
        }
    }

    private func canvasButton(
        systemName: String,
        label: String,
        isEnabled: Bool = true,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .help(label)
        .accessibilityLabel(label)
    }

    private func draw(_ shape: DrawableShape, in context: inout GraphicsContext) {
        let strokeStyle = StrokeStyle(
            lineWidth: shape.strokeWidth,
            lineCap: .round,
            lineJoin: .round
        )

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
            context.stroke(
                Circle().path(in: circleRect),
                with: .color(shape.color),
                style: strokeStyle
            )
        case .square:
            context.stroke(
                Rectangle().path(in: shape.squareRect),
                with: .color(shape.color),
                style: strokeStyle
            )
        case .rectangle:
            context.stroke(
                Rectangle().path(in: shape.rect),
                with: .color(shape.color),
                style: strokeStyle
            )
        case .text:
            guard let text = shape.text else { return }
            let resolvedText = context.resolve(
                Text(verbatim: text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(shape.color)
            )
            context.draw(resolvedText, at: shape.startPoint, anchor: .topLeading)
        }
    }
}
