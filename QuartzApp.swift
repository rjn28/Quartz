import SwiftUI

@main
struct QuartzApp: App {
    static let editorWindowID = "editor-window"

    var body: some Scene {
        WindowGroup(id: Self.editorWindowID) {
            EditorWindowView()
                .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            QuartzCommands()
        }
    }
}

private struct EditorWindowView: View {
    @State private var windowID = UUID()

    var body: some View {
        ContentView(windowID: windowID)
    }
}

private struct QuartzCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(id: QuartzApp.editorWindowID)
            }
            .keyboardShortcut("n")
        }

        SidebarCommands()
    }
}

// Helper for window background translucency if needed at the window level
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
