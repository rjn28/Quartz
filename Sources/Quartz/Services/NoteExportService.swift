import Foundation

enum NoteExportError: LocalizedError {
    case desktopDirectoryUnavailable
    case pdfContextCreationFailed
    case pdfRenderingFailed

    var errorDescription: String? {
        switch self {
        case .desktopDirectoryUnavailable:
            "Quartz could not access the Desktop folder."
        case .pdfContextCreationFailed:
            "Quartz could not create the PDF document."
        case .pdfRenderingFailed:
            "Quartz could not render the note as a PDF."
        }
    }
}

struct NoteExportService {
    let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func createTemporaryTextFile(
        text: String,
        date: Date = Date(),
        directory: URL? = nil
    ) throws -> URL {
        let directory = directory ?? fileManager.temporaryDirectory
        let url = availableURL(
            in: directory,
            baseName: "Quartz Note \(Self.timestamp(for: date))",
            pathExtension: "txt"
        )
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func exportTextToDesktop(
        text: String,
        date: Date = Date(),
        desktopDirectory: URL? = nil
    ) throws -> URL {
        let directory = try resolvedDesktopDirectory(override: desktopDirectory)
        let url = availableURL(
            in: directory,
            baseName: "Quartz Note \(Self.timestamp(for: date))",
            pathExtension: "txt"
        )
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func copyToDesktop(
        sourceURL: URL,
        desktopDirectory: URL? = nil
    ) throws -> URL {
        let directory = try resolvedDesktopDirectory(override: desktopDirectory)
        let url = availableURL(
            in: directory,
            baseName: sourceURL.deletingPathExtension().lastPathComponent,
            pathExtension: sourceURL.pathExtension
        )
        try fileManager.copyItem(at: sourceURL, to: url)
        return url
    }

    func availableURL(in directory: URL, baseName: String, pathExtension: String) -> URL {
        var suffix = 1
        var candidate = directory
            .appendingPathComponent(baseName, isDirectory: false)
            .appendingPathExtension(pathExtension)

        while fileManager.fileExists(atPath: candidate.path) {
            suffix += 1
            candidate = directory
                .appendingPathComponent("\(baseName) \(suffix)", isDirectory: false)
                .appendingPathExtension(pathExtension)
        }

        return candidate
    }

    static func timestamp(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter.string(from: date)
    }

    private func resolvedDesktopDirectory(override: URL?) throws -> URL {
        if let override { return override }
        guard let directory = fileManager.urls(
            for: .desktopDirectory,
            in: .userDomainMask
        ).first else {
            throw NoteExportError.desktopDirectoryUnavailable
        }
        return directory
    }
}
