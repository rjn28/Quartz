import SwiftUI

@main
struct QuartzApp: App {
    @StateObject private var noteLibrary = QuartzNoteLibrary.shared

    var body: some Scene {
        WindowGroup(for: EditorRoute.self) { route in
            EditorWindowView(route: route.wrappedValue ?? noteLibrary.makeNewRoute())
                .background(VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            QuartzCommands(noteLibrary: noteLibrary)
        }
    }
}

private struct EditorWindowView: View {
    let route: EditorRoute

    var body: some View {
        ContentView(route: route)
    }
}

private struct QuartzCommands: Commands {
    @ObservedObject var noteLibrary: QuartzNoteLibrary
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(value: noteLibrary.makeNewRoute())
            }
            .keyboardShortcut("n")
        }

        CommandGroup(after: .newItem) {
            Menu("Saved Texts") {
                if noteLibrary.savedNotes.isEmpty {
                    Text("No saved texts")
                } else {
                    ForEach(noteLibrary.savedNotes) { note in
                        Button(note.menuTitle) {
                            openWindow(value: noteLibrary.makeRoute(for: note.id))
                        }
                    }
                }
            }
        }

        SidebarCommands()
    }
}

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
