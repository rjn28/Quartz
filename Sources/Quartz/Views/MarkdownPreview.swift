import SwiftUI

struct MarkdownPreview: View {
    let text: String
    let fontSize: CGFloat
    let isDarkMode: Bool

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 8) {
            contentLines
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var contentLines: some View {
        ForEach(Array(text.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
            view(for: line)
        }
    }

    @ViewBuilder
    private func view(for line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("# ") {
            heading(String(trimmed.dropFirst(2)), scale: 2, weight: .bold)
                .padding(.top, 10)
        } else if trimmed.hasPrefix("## ") {
            heading(String(trimmed.dropFirst(3)), scale: 1.6, weight: .bold)
                .padding(.top, 8)
        } else if trimmed.hasPrefix("### ") {
            heading(String(trimmed.dropFirst(4)), scale: 1.3, weight: .semibold)
                .padding(.top, 6)
        } else if trimmed.hasPrefix("> ") {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(.secondary)
                    .frame(width: 4)
                inlineMarkdown(String(trimmed.dropFirst(2)))
                    .font(previewFont(size: fontSize, design: .serif))
                    .italic()
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
        } else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
            listItem(String(trimmed.dropFirst(2)), marker: "•")
        } else if let orderedItem = orderedListItem(from: trimmed) {
            listItem(orderedItem.content, marker: orderedItem.marker)
        } else if trimmed == "---" {
            Divider()
                .padding(.vertical, 8)
        } else if trimmed.isEmpty {
            Color.clear
                .frame(height: fontSize / 2)
                .accessibilityHidden(true)
        } else {
            inlineMarkdown(line)
                .font(previewFont(size: fontSize, design: .rounded))
                .foregroundStyle(textColor)
                .lineSpacing(4)
        }
    }

    private func heading(_ content: String, scale: CGFloat, weight: Font.Weight) -> some View {
        inlineMarkdown(content)
            .font(previewFont(size: fontSize * scale, weight: weight, design: .rounded))
            .foregroundStyle(textColor)
            .accessibilityAddTraits(.isHeader)
    }

    private func listItem(_ content: String, marker: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(verbatim: marker)
                .font(previewFont(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
            inlineMarkdown(content)
                .font(previewFont(size: fontSize, design: .rounded))
                .foregroundStyle(textColor)
        }
    }

    private func inlineMarkdown(_ content: String) -> Text {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        guard let attributed = try? AttributedString(markdown: content, options: options) else {
            return Text(verbatim: content)
        }
        return Text(attributed)
    }

    private func orderedListItem(from content: String) -> (marker: String, content: String)? {
        guard let separator = content.firstIndex(of: ".") else { return nil }
        let number = content[..<separator]
        let remainder = content[content.index(after: separator)...]
        guard !number.isEmpty,
              number.allSatisfy(\.isNumber),
              remainder.first == " " else {
            return nil
        }
        return ("\(number).", String(remainder.dropFirst()))
    }

    private var textColor: Color { isDarkMode ? .white : .black }

    private func previewFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design
    ) -> Font {
        return .system(size: size, weight: weight, design: design)
    }
}
