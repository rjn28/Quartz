import Foundation

struct EditorRoute: Hashable, Codable, Sendable {
    let noteID: UUID
}

enum EditorMode: String, CaseIterable, Identifiable, Sendable {
    case editor
    case preview
    case split

    var id: Self { self }

    init(isPreviewMode: Bool, isSplitView: Bool) {
        if isSplitView {
            self = .split
        } else if isPreviewMode {
            self = .preview
        } else {
            self = .editor
        }
    }

    var isPreviewMode: Bool { self == .preview }
    var isSplitView: Bool { self == .split }
}

enum TextStatType: String, CaseIterable, Identifiable, Sendable {
    case words = "Words"
    case charactersWithSpaces = "Chars (with spaces)"
    case charactersNoSpaces = "Chars (no spaces)"
    case lines = "Lines"
    case readingTime = "Reading Time"

    var id: Self { self }
}

enum QuartzFontSize: CGFloat, CaseIterable, Identifiable, Sendable {
    case normal = 18
    case large = 24
    case extraLarge = 32

    var id: Self { self }

    var label: String {
        switch self {
        case .normal: "Normal"
        case .large: "Large"
        case .extraLarge: "Extra Large"
        }
    }
}

struct TextStatistics: Equatable, Sendable {
    let text: String

    var wordCount: Int {
        text.split(whereSeparator: \Character.isWhitespace).count
    }

    var characterCountWithSpaces: Int { text.count }

    var characterCountWithoutSpaces: Int {
        text.lazy.filter { !$0.isWhitespace }.count
    }

    var lineCount: Int {
        text.isEmpty ? 0 : text.components(separatedBy: .newlines).count
    }

    var readingMinutes: Int {
        guard wordCount > 0 else { return 0 }
        return Int(ceil(Double(wordCount) / 200.0))
    }

    func label(for type: TextStatType) -> String {
        switch type {
        case .words:
            "\(wordCount) words"
        case .charactersWithSpaces:
            "\(characterCountWithSpaces) chars"
        case .charactersNoSpaces:
            "\(characterCountWithoutSpaces) chars"
        case .lines:
            "\(lineCount) lines"
        case .readingTime:
            readingMinutes == 0 ? "< 1 min read" : "\(readingMinutes) min read"
        }
    }
}
