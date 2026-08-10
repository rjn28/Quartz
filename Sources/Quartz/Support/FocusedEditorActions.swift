import SwiftUI

struct EditorActions {
    let setMode: (EditorMode) -> Void
    let toggleCanvas: () -> Void
    let showControls: () -> Void
}

private struct EditorActionsKey: FocusedValueKey {
    typealias Value = EditorActions
}

extension FocusedValues {
    var editorActions: EditorActions? {
        get { self[EditorActionsKey.self] }
        set { self[EditorActionsKey.self] = newValue }
    }
}
