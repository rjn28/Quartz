import SwiftUI

@main
struct QuartzApp: App {
    @StateObject private var noteLibrary = QuartzNoteLibrary.shared

    var body: some Scene {
        WindowGroup("Quartz", for: EditorRoute.self) { route in
            ContentView(route: route.wrappedValue)
        } defaultValue: {
            EditorRoute(noteID: UUID())
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 960, height: 680)
        .commands {
            QuartzCommands(noteLibrary: noteLibrary)
        }
    }
}

private struct QuartzCommands: Commands {
    @ObservedObject var noteLibrary: QuartzNoteLibrary
    @Environment(\.openWindow) private var openWindow
    @FocusedValue(\.editorActions) private var editorActions

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Note") {
                openWindow(value: noteLibrary.makeNewRoute())
            }
            .keyboardShortcut("n")
        }

        CommandMenu("Notes") {
            Menu("Saved Notes") {
                if noteLibrary.savedNotes.isEmpty {
                    Text("No saved notes")
                } else {
                    ForEach(noteLibrary.savedNotes) { note in
                        Button(note.menuTitle) {
                            openWindow(value: noteLibrary.makeRoute(for: note.id))
                        }
                    }
                }
            }

            Divider()

            Button("Show Controls") { editorActions?.showControls() }
                .keyboardShortcut("0")
                .disabled(editorActions == nil)

            Button("Editor Mode") { editorActions?.setMode(.editor) }
                .keyboardShortcut("1")
                .disabled(editorActions == nil)
            Button("Preview Mode") { editorActions?.setMode(.preview) }
                .keyboardShortcut("2")
                .disabled(editorActions == nil)
            Button("Split Mode") { editorActions?.setMode(.split) }
                .keyboardShortcut("3")
                .disabled(editorActions == nil)

            Divider()

            Button("Toggle Drawing Canvas") { editorActions?.toggleCanvas() }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                .disabled(editorActions == nil)
        }
    }
}
