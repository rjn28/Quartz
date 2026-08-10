import SwiftUI

struct EditorControlsView: View {
    @Binding var isDarkMode: Bool
    @Binding var fontSize: QuartzFontSize
    @Binding var editorMode: EditorMode
    @Binding var selectedStat: TextStatType
    let statText: String
    let isCanvasPresented: Bool
    let canClearText: Bool
    let newWindow: () -> Void
    let toggleCanvas: () -> Void
    let requestClear: () -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                iconButton(
                    systemName: isDarkMode ? "sun.max.fill" : "moon.fill",
                    label: isDarkMode ? "Use light appearance" : "Use dark appearance"
                ) {
                    isDarkMode.toggle()
                }

                divider

                iconButton(
                    systemName: "plus.rectangle.on.rectangle",
                    label: "New note window",
                    action: newWindow
                )

                divider

                fontSizeMenu

                divider

                modePicker

                divider

                statisticsMenu

                divider

                iconButton(
                    systemName: "pencil.and.scribble",
                    label: isCanvasPresented ? "Close drawing canvas" : "Open drawing canvas",
                    isSelected: isCanvasPresented,
                    action: toggleCanvas
                )

                divider

                iconButton(
                    systemName: "eraser.fill",
                    label: "Clear note text",
                    role: .destructive,
                    action: requestClear
                )
                .disabled(!canClearText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
        .fixedSize(horizontal: true, vertical: false)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.primary.opacity(0.12), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 3)
    }

    private var divider: some View {
        Rectangle()
            .fill(.primary.opacity(0.16))
            .frame(width: 1, height: 18)
            .accessibilityHidden(true)
    }

    private var fontSizeMenu: some View {
        Menu {
            ForEach(QuartzFontSize.allCases) { size in
                Button {
                    fontSize = size
                } label: {
                    if size == fontSize {
                        Label(size.label, systemImage: "checkmark")
                    } else {
                        Text(size.label)
                    }
                }
            }
        } label: {
            Image(systemName: "textformat.size")
                .frame(width: 24, height: 24)
        }
        .menuStyle(.borderlessButton)
        .help("Change font size")
        .accessibilityLabel("Font size")
        .accessibilityValue(fontSize.label)
    }

    private var modePicker: some View {
        Picker("Editor mode", selection: $editorMode) {
            Label("Editor", systemImage: "square.and.pencil")
                .tag(EditorMode.editor)
            Label("Preview", systemImage: "eye")
                .tag(EditorMode.preview)
            Label("Split", systemImage: "rectangle.split.2x1")
                .tag(EditorMode.split)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .fixedSize()
        .help("Choose editor, preview, or split mode")
    }

    private var statisticsMenu: some View {
        Menu {
            ForEach(TextStatType.allCases) { statistic in
                Button {
                    selectedStat = statistic
                } label: {
                    if statistic == selectedStat {
                        Label(statistic.rawValue, systemImage: "checkmark")
                    } else {
                        Text(statistic.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(statText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel("Text statistics")
        .accessibilityValue(statText)
    }

    private func iconButton(
        systemName: String,
        label: String,
        isSelected: Bool = false,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

struct ExportButton: View {
    enum Format {
        case text
        case pdf

        var label: String { self == .text ? "TXT" : "PDF" }
        var help: String { "Save or drag \(label) export" }
    }

    let format: Format
    let export: () -> Void
    let itemProvider: () -> NSItemProvider

    var body: some View {
        Button(action: export) {
            Text(format.label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.primary.opacity(0.12), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .onDrag(itemProvider)
        .help(format.help)
        .accessibilityLabel(format.help)
    }
}
