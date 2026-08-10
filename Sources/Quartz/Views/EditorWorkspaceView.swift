import SwiftUI

struct EditorWorkspaceView: View {
    @Binding var text: String
    let mode: EditorMode
    let fontSize: CGFloat
    let isDarkMode: Bool
    let isFocused: FocusState<Bool>.Binding

    var body: some View {
        Group {
            switch mode {
            case .editor:
                editor
            case .preview:
                preview
            case .split:
                HSplitView {
                    editor
                        .frame(minWidth: 280)
                    preview
                        .frame(minWidth: 280)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var editor: some View {
        TextEditor(text: $text)
            .font(.system(size: fontSize, design: .rounded))
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 84)
            .focused(isFocused)
            .accessibilityLabel("Note editor")
    }

    private var preview: some View {
        ScrollView {
            MarkdownPreview(
                text: text,
                fontSize: fontSize,
                isDarkMode: isDarkMode
            )
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 100)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel("Markdown preview")
    }
}
