import Foundation

struct QuartzNote: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let createdAt: Date
    var updatedAt: Date
    var text: String
    var isDarkMode: Bool
    var selectedStatRawValue: String
    var fontSizeRawValue: Double
    var isPreviewMode: Bool
    var isSplitView: Bool
    var canvasData: Data?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        text: String = "",
        isDarkMode: Bool = true,
        selectedStatRawValue: String = TextStatType.words.rawValue,
        fontSizeRawValue: Double = Double(QuartzFontSize.normal.rawValue),
        isPreviewMode: Bool = false,
        isSplitView: Bool = false,
        canvasData: Data? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.text = text
        self.isDarkMode = isDarkMode
        self.selectedStatRawValue = selectedStatRawValue
        self.fontSizeRawValue = fontSizeRawValue
        self.isPreviewMode = isPreviewMode
        self.isSplitView = isSplitView
        self.canvasData = canvasData
    }

    var title: String {
        let firstLine = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        return firstLine.map { String($0.prefix(40)) } ?? "Untitled Note"
    }

    var menuTitle: String {
        let date = updatedAt.formatted(date: .numeric, time: .shortened)
        return String("\(title) · \(date)".prefix(30))
    }

    var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            canvasData?.isEmpty == false
    }
}
