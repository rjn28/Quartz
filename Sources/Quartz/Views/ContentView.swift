import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var isEditorFocused: Bool
    @StateObject private var viewModel: QuartzViewModel
    @State private var controlsAreVisible = true
    @State private var showClearConfirmation = false
    @State private var showDrawingCanvas = false
    @State private var inactivityTask: Task<Void, Never>?
    @State private var noticeTask: Task<Void, Never>?
    @State private var exportNotice: String?
    @State private var presentedError: PresentedError?

    private let exportService = NoteExportService()
    private let pdfExportService = PDFExportService()

    init(route: EditorRoute) {
        _viewModel = StateObject(wrappedValue: QuartzViewModel(noteID: route.noteID))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(nsColor: .textBackgroundColor)
                .ignoresSafeArea()

            EditorWorkspaceView(
                text: $viewModel.text,
                mode: viewModel.editorMode,
                fontSize: viewModel.fontSize.rawValue,
                isDarkMode: viewModel.isDarkMode,
                isFocused: $isEditorFocused
            )

            if controlsAreVisible {
                controlsLayer
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if showDrawingCanvas {
                DrawingCanvasView(
                    isPresented: $showDrawingCanvas,
                    isDarkMode: viewModel.isDarkMode,
                    noteID: viewModel.noteID
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }

            if let exportNotice {
                exportNoticeView(exportNotice)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .zIndex(20)
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        .focusedValue(
            \.editorActions,
            EditorActions(
                setMode: { viewModel.editorMode = $0 },
                toggleCanvas: toggleCanvas,
                showControls: showControls
            )
        )
        .onContinuousHover { phase in
            if case .active = phase {
                showControls()
            }
        }
        .onChange(of: viewModel.text) { _, _ in
            setControlsVisible(false)
            scheduleControlsAutoHide()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(100))
            isEditorFocused = true
            scheduleControlsAutoHide()
        }
        .onDisappear {
            inactivityTask?.cancel()
            noticeTask?.cancel()
            viewModel.flush()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                viewModel.flush()
            }
        }
        .confirmationDialog(
            "Clear this note?",
            isPresented: $showClearConfirmation
        ) {
            Button("Clear Text", role: .destructive) {
                viewModel.clearText()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The drawing canvas is kept. This action cannot be undone.")
        }
        .alert(item: $presentedError) { error in
            Alert(
                title: Text("Export Failed"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var controlsLayer: some View {
        ZStack(alignment: .bottomTrailing) {
            EditorControlsView(
                isDarkMode: $viewModel.isDarkMode,
                fontSize: $viewModel.fontSize,
                editorMode: $viewModel.editorMode,
                selectedStat: $viewModel.selectedStat,
                statText: viewModel.statText,
                isCanvasPresented: showDrawingCanvas,
                canClearText: !viewModel.text.isEmpty,
                newWindow: openNewWindow,
                toggleCanvas: toggleCanvas,
                requestClear: { showClearConfirmation = true }
            )
            .frame(maxWidth: .infinity)

            ExportButton(
                format: viewModel.editorMode == .editor ? .text : .pdf,
                export: exportCurrentNote,
                itemProvider: makeDragItemProvider
            )
        }
        .padding(20)
    }

    private func exportNoticeView(_ message: String) -> some View {
        VStack {
            HStack {
                Spacer()
                Label(message, systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 8, y: 3)
            }
            Spacer()
        }
        .padding(20)
    }

    private func openNewWindow() {
        openWindow(value: QuartzNoteLibrary.shared.makeNewRoute())
    }

    private func toggleCanvas() {
        withOptionalAnimation {
            showDrawingCanvas.toggle()
        }
    }

    private func exportCurrentNote() {
        do {
            let url: URL
            if viewModel.editorMode == .editor {
                url = try viewModel.exportTextToDesktop()
            } else {
                let temporaryURL = try pdfExportService.createTemporaryPDF(
                    text: viewModel.text,
                    fontSize: viewModel.fontSize.rawValue
                )
                url = try exportService.copyToDesktop(sourceURL: temporaryURL)
            }
            presentExportNotice("Saved \(url.lastPathComponent)")
        } catch {
            presentedError = PresentedError(error)
        }
    }

    private func makeDragItemProvider() -> NSItemProvider {
        do {
            let url = if viewModel.editorMode == .editor {
                try viewModel.createTemporaryTextFile()
            } else {
                try pdfExportService.createTemporaryPDF(
                    text: viewModel.text,
                    fontSize: viewModel.fontSize.rawValue
                )
            }

            guard let provider = NSItemProvider(contentsOf: url) else {
                throw NoteExportError.pdfRenderingFailed
            }
            return provider
        } catch {
            presentedError = PresentedError(error)
            return NSItemProvider()
        }
    }

    private func presentExportNotice(_ message: String) {
        noticeTask?.cancel()
        withOptionalAnimation {
            exportNotice = message
        }
        noticeTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withOptionalAnimation {
                exportNotice = nil
            }
        }
    }

    private func showControls() {
        if !controlsAreVisible {
            setControlsVisible(true)
        }
        scheduleControlsAutoHide()
    }

    private func scheduleControlsAutoHide() {
        inactivityTask?.cancel()
        inactivityTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            setControlsVisible(false)
        }
    }

    private func setControlsVisible(_ isVisible: Bool) {
        withOptionalAnimation {
            controlsAreVisible = isVisible
        }
    }

    private func withOptionalAnimation(_ updates: () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(.easeInOut(duration: 0.25), updates)
        }
    }
}

private struct PresentedError: Identifiable {
    let id = UUID()
    let message: String

    init(_ error: Error) {
        message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
