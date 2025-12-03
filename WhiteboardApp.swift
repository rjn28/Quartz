import SwiftUI

@main
struct WhiteboardApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Minimal commands, removing unnecessary default menus if needed
            SidebarCommands() // Removes sidebar toggle if not needed
        }
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
