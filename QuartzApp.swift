import SwiftUI

@main
struct QuartzApp: App {
    @StateObject private var windowSessionStore = WindowSessionStore.shared

    var body: some Scene {
        WindowGroup(for: UUID.self) { windowID in
            EditorWindowView(sceneWindowID: windowID.wrappedValue)
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
    let sceneWindowID: UUID?
    @Environment(\.openWindow) private var openWindow
    @State private var resolvedWindowID: UUID

    var body: some View {
        ContentView(windowID: resolvedWindowID)
            .onAppear {
                WindowSessionStore.shared.markWindowOpened(resolvedWindowID)
                WindowSessionStore.shared.restoreRemainingWindows(with: openWindow)
            }
            .onDisappear {
                WindowSessionStore.shared.markWindowClosed(resolvedWindowID)
            }
    }

    init(sceneWindowID: UUID?) {
        self.sceneWindowID = sceneWindowID
        _resolvedWindowID = State(initialValue: sceneWindowID ?? WindowSessionStore.shared.consumeLaunchWindowID())
    }
}

private struct QuartzCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(value: WindowSessionStore.shared.makeNewWindowID())
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
