import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = QuartzViewModel()
    @FocusState private var isFocused: Bool
    @State private var showClearConfirmation = false
    
    // UI State
    @State private var controlsOpacity: Double = 1.0
    @State private var inactivityTimer: Timer?
    @State private var eventMonitor: Any?
    
    // Drag Gesture State for Menu (Optional, keeping it as requested previously)
    @State private var menuOffset = CGSize.zero
    @GestureState private var dragOffset = CGSize.zero
    
    // Throttle for mouse movement (optimization)
    @State private var lastMouseEventTime: Date = .distantPast
    
    var body: some View {
        ZStack {
            // MARK: - Background
            Color(viewModel.isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.12) : .white)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: viewModel.isDarkMode)
            
            // Access underlying window to enable mouse moved events
            WindowAccessor()
                .frame(width: 0, height: 0)
            
            // MARK: - Canvas
            Group {
                if viewModel.isSplitView {
                    // Split View: Editor on left, Preview on right
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // Left: Editor
                            TextEditor(text: $viewModel.text)
                                .font(.system(size: viewModel.fontSize.rawValue, design: .rounded))
                                .foregroundColor(viewModel.isDarkMode ? .white : .black)
                                .scrollContentBackground(.hidden)
                                .padding(.horizontal, 20)
                                .padding(.top, 32)
                                .focused($isFocused)
                                .frame(width: geometry.size.width / 2)
                                .background(viewModel.isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.12) : .white)
                            
                            // Divider
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1)
                            
                            // Right: Preview
                            ScrollView {
                                MarkdownPreview(text: viewModel.text, fontSize: viewModel.fontSize.rawValue, isDarkMode: viewModel.isDarkMode)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 32)
                                    .padding(.bottom, 100)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(width: geometry.size.width / 2 - 1)
                            .background(viewModel.isDarkMode ? Color(red: 0.12, green: 0.12, blue: 0.12) : .white)
                        }
                    }
                } else if viewModel.isPreviewMode {
                    // Preview Only
                    ScrollView {
                        MarkdownPreview(text: viewModel.text, fontSize: viewModel.fontSize.rawValue, isDarkMode: viewModel.isDarkMode)
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                            .padding(.bottom, 100)
                    }
                } else {
                    // Editor Only
                    TextEditor(text: $viewModel.text)
                        .font(.system(size: viewModel.fontSize.rawValue, design: .rounded))
                        .foregroundColor(viewModel.isDarkMode ? .white : .black)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 0)
                        .ignoresSafeArea()
                        .focused($isFocused)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: viewModel.text) { _, _ in
                // Typing triggers "Zen Mode" immediately
                withAnimation(.easeOut(duration: 0.5)) {
                    controlsOpacity = 0.0
                }
                resetInactivityTimer() // Reset timer so it doesn't pop back up unexpectedly
            }
            
            // MARK: - Controls Layer
            ZStack(alignment: .bottom) { // Changed to .bottom alignment
                // Removed the blocking Color.clear layer
                
                // Bottom Center Menu
                menuView
                    .scaleEffect(0.9) // Make the whole menu slightly smaller/discreet
                    .offset(x: menuOffset.width + dragOffset.width, y: menuOffset.height + dragOffset.height)
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                            }
                            .onEnded { value in
                                menuOffset.width += value.translation.width
                                menuOffset.height += value.translation.height
                            }
                    )
                    .padding(.bottom, 20) // Move to the bottom with some padding
                
                // Bottom Right TXT Button (kept at bottom right via Spacer)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        txtExportButton
                    }
                    .padding(20)
                }
            }
            .opacity(controlsOpacity)
            .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
            // Allow touches to pass through empty areas of the ZStack to the TextEditor
            .allowsHitTesting(controlsOpacity > 0) // Only block if visible (and even then, we want pass-through)

        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
            startInactivityTimer()
            
            // Monitor global mouse movement in the window (with throttle)
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [self] event in
                let now = Date()
                // Throttle: only react every 100ms
                if now.timeIntervalSince(lastMouseEventTime) > 0.1 {
                    lastMouseEventTime = now
                    showControls()
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
    
    // MARK: - Subviews
    
    var menuView: some View {
        HStack(spacing: 20) {
            // Theme Toggle
            Button(action: {
                viewModel.toggleTheme()
            }) {
                Image(systemName: viewModel.isDarkMode ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            .help("Toggle Theme")
            
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 16)
            
            // Font Size Menu
            Menu {
                ForEach(QuartzFontSize.allCases) { size in
                    Button(action: {
                        viewModel.fontSize = size
                    }) {
                        if size == viewModel.fontSize {
                            Label(size.label, systemImage: "checkmark")
                        } else {
                            Text(size.label)
                        }
                    }
                }
            } label: {
                Image(systemName: "textformat.size")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            .help("Change Font Size")

            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 16)
            
            // Split View Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isSplitView.toggle()
                    if viewModel.isSplitView {
                        viewModel.isPreviewMode = false
                    }
                }
            }) {
                Image(systemName: viewModel.isSplitView ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.isSplitView ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Toggle Split View")
            
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 16)
            
            // Markdown Preview Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.isPreviewMode.toggle()
                    if viewModel.isPreviewMode {
                        viewModel.isSplitView = false
                    }
                }
            }) {
                Image(systemName: viewModel.isPreviewMode ? "eye.fill" : "eye")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.isPreviewMode ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Toggle Markdown Preview")
            
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 16)
            
            // Stat Switcher
            Menu {
                ForEach(TextStatType.allCases) { stat in
                    Button(action: {
                        viewModel.selectedStat = stat
                        viewModel.refreshStats() // Update immediately when user changes stat type
                    }) {
                        if stat == viewModel.selectedStat {
                            Label(stat.rawValue, systemImage: "checkmark")
                        } else {
                            Text(stat.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.statText)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .frame(minWidth: 60, alignment: .trailing)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.secondary)
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            
            Rectangle()
                .fill(Color.primary.opacity(0.2))
                .frame(width: 1, height: 16)
            
            // Clear Board
            Button(action: {
                showClearConfirmation = true
            }) {
                Image(systemName: "eraser.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help("Clear Board")
            .confirmationDialog("Clear Quartz?", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    viewModel.clearBoard()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            ZStack(alignment: .bottom) {
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 0.5)
                
                // Drag Handle
                Capsule()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.bottom, 5)
            }
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    var txtExportButton: some View {
        Button(action: {
            viewModel.exportToDesktop()
        }) {
            Text("TXT")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.2), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain) // Standard button style for custom look
        .onDrag {
            let fileURL = viewModel.createTempFile()
            return NSItemProvider(contentsOf: fileURL)!
        }
        .help("Click to save to Desktop, Drag to export")
    }
    
    // MARK: - Logic
    
    func startInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 1.0)) {
                controlsOpacity = 0.0
            }
        }
    }
    
    func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        startInactivityTimer()
    }
    
    func showControls() {
        if controlsOpacity < 1.0 {
            withAnimation(.easeIn(duration: 0.2)) {
                controlsOpacity = 1.0
            }
        }
        resetInactivityTimer()
    }
}

// Helper to enable mouse moved events on the window
struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.acceptsMouseMovedEvents = true
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Markdown Preview Helper
struct MarkdownPreview: View {
    let text: String
    let fontSize: CGFloat
    let isDarkMode: Bool
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(text.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                mapLineToView(line)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func mapLineToView(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("# ") {
            // H1
            Text(LocalizedStringKey(trimmed.dropFirst(2).description))
                .font(.system(size: fontSize * 2.0, weight: .bold, design: .rounded))
                .foregroundColor(isDarkMode ? .white : .black)
                .padding(.top, 10)
        } else if trimmed.hasPrefix("## ") {
            // H2
            headingText(trimmed.dropFirst(3).description, scale: 1.6, weight: .bold)
                .padding(.top, 8)
        } else if trimmed.hasPrefix("### ") {
            // H3
            headingText(trimmed.dropFirst(4).description, scale: 1.3, weight: .semibold)
                .padding(.top, 6)
        } else if trimmed.hasPrefix("> ") {
            // Blockquote
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 4)
                Text(LocalizedStringKey(trimmed.dropFirst(2).description))
                    .font(.system(size: fontSize, design: .serif))
                    .italic()
                    .foregroundColor(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        } else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
            // List Item
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : .black)
                Text(LocalizedStringKey(trimmed.dropFirst(2).description))
                    .font(.system(size: fontSize, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : .black)
            }
        } else if trimmed == "---" {
            // Horizontal Rule
            Divider()
                .background(Color.gray)
                .padding(.vertical, 8)
        } else {
            // Body Text (handling empty lines as spacers)
            if trimmed.isEmpty {
                Text(" ") // Spacer
                    .font(.system(size: fontSize / 2))
            } else {
                Text(LocalizedStringKey(line))
                    .font(.system(size: fontSize, design: .rounded))
                    .foregroundColor(isDarkMode ? .white : .black)
                    // Basic line height improvement
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - Helper for headings (reduces code duplication)
    private func headingText(_ content: String, scale: CGFloat, weight: Font.Weight) -> some View {
        Text(LocalizedStringKey(content))
            .font(.system(size: fontSize * scale, weight: weight, design: .rounded))
            .foregroundColor(isDarkMode ? .white : .black)
    }
}
