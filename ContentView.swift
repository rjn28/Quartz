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
            TextEditor(text: $viewModel.text)
                .font(.system(.body, design: .rounded))
                .foregroundColor(viewModel.isDarkMode ? .white : .black)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 20)
                .padding(.top, 32) // Avoid traffic lights
                .padding(.bottom, 0)
                .ignoresSafeArea() // Fill the rest of the window
                .focused($isFocused)
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
            
            // Monitor global mouse movement in the window
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
                showControls()
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
            
            Divider()
                .frame(height: 16)
            
            // Stat Switcher
            Menu {
                ForEach(TextStatType.allCases) { stat in
                    Button(action: {
                        viewModel.selectedStat = stat
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
            
            Divider()
                .frame(height: 16)
            
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
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
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
