import PDFKit
import XCTest
@testable import Quartz

@MainActor
final class ExportTests: XCTestCase {
    func testTextExportWritesContentAndAvoidsCollisions() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = NoteExportService()
        let date = Date(timeIntervalSince1970: 0)

        let first = try service.createTemporaryTextFile(
            text: "First",
            date: date,
            directory: directory
        )
        let second = try service.createTemporaryTextFile(
            text: "Second",
            date: date,
            directory: directory
        )

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(try String(contentsOf: first, encoding: .utf8), "First")
        XCTAssertEqual(try String(contentsOf: second, encoding: .utf8), "Second")
        XCTAssertTrue(second.deletingPathExtension().lastPathComponent.hasSuffix(" 2"))
    }

    func testCopyToDesktopUsesAUniqueDestination() throws {
        let sourceDirectory = try makeTemporaryDirectory()
        let desktopDirectory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: sourceDirectory)
            try? FileManager.default.removeItem(at: desktopDirectory)
        }
        let source = sourceDirectory.appendingPathComponent("Quartz Note.pdf")
        try Data("pdf".utf8).write(to: source)
        let service = NoteExportService()

        let first = try service.copyToDesktop(
            sourceURL: source,
            desktopDirectory: desktopDirectory
        )
        let second = try service.copyToDesktop(
            sourceURL: source,
            desktopDirectory: desktopDirectory
        )

        XCTAssertNotEqual(first, second)
        XCTAssertEqual(try Data(contentsOf: second), Data("pdf".utf8))
    }

    func testPDFExportCreatesAReadableDocument() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = PDFExportService()

        let url = try service.createTemporaryPDF(
            text: "# Quartz\n\nA focused writing space.",
            fontSize: 18,
            date: Date(timeIntervalSince1970: 0),
            directory: directory
        )

        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertEqual(document.pageCount, 1)
    }

    func testPDFExportHandlesMarkdownThatParsesAsEmpty() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = PDFExportService()

        let url = try service.createTemporaryPDF(
            text: "[]()",
            fontSize: 18,
            date: Date(timeIntervalSince1970: 3),
            directory: directory
        )

        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertEqual(document.pageCount, 1)
    }

    func testQuotedPDFTextRemainsVisibleWithDarkSystemAppearance() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let appearance = try XCTUnwrap(NSAppearance(named: .darkAqua))
        var exportedURL: URL?
        var exportError: Error?

        appearance.performAsCurrentDrawingAppearance {
            do {
                exportedURL = try PDFExportService().createTemporaryPDF(
                    text: "> Quartz quote",
                    fontSize: 18,
                    date: Date(timeIntervalSince1970: 4),
                    directory: directory
                )
            } catch {
                exportError = error
            }
        }
        if let exportError { throw exportError }
        let url = try XCTUnwrap(exportedURL)
        let document = try XCTUnwrap(PDFDocument(url: url))
        let page = try XCTUnwrap(document.page(at: 0))
        let thumbnail = page.thumbnail(
            of: CGSize(width: 240, height: 340),
            for: PDFDisplayBox.mediaBox
        )
        let representation = try XCTUnwrap(
            thumbnail.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:))
        )

        var visiblePixelCount = 0
        for y in stride(from: 0, to: representation.pixelsHigh, by: 2) {
            for x in stride(from: 0, to: representation.pixelsWide, by: 2) {
                guard let color = representation.colorAt(x: x, y: y)?.usingColorSpace(NSColorSpace.sRGB) else {
                    continue
                }
                if color.redComponent < 0.8 || color.greenComponent < 0.8 || color.blueComponent < 0.8 {
                    visiblePixelCount += 1
                }
            }
        }
        XCTAssertGreaterThan(visiblePixelCount, 5)
    }

    func testMarkdownDividerRendersAsOneRule() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try PDFExportService().createTemporaryPDF(
            text: "---",
            fontSize: 32,
            date: Date(timeIntervalSince1970: 5),
            directory: directory
        )
        let document = try XCTUnwrap(PDFDocument(url: url))
        let page = try XCTUnwrap(document.page(at: 0))
        let thumbnail = page.thumbnail(
            of: CGSize(width: 240, height: 340),
            for: PDFDisplayBox.mediaBox
        )
        let representation = try XCTUnwrap(
            thumbnail.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:))
        )

        var inkRows: [Int] = []
        for y in 0..<representation.pixelsHigh {
            let hasInk = (0..<representation.pixelsWide).contains { x in
                guard let color = representation.colorAt(x: x, y: y)?.usingColorSpace(NSColorSpace.sRGB) else {
                    return false
                }
                return color.redComponent < 0.9 || color.greenComponent < 0.9 || color.blueComponent < 0.9
            }
            if hasInk { inkRows.append(y) }
        }

        let clusterCount = zip(inkRows, inkRows.dropFirst()).reduce(inkRows.isEmpty ? 0 : 1) { count, pair in
            count + (pair.1 > pair.0 + 1 ? 1 : 0)
        }
        XCTAssertEqual(clusterCount, 1)
    }

    func testLongPDFExportIsPaginated() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = PDFExportService()
        let text = (1...180).map { "Line \($0): Quartz keeps this content readable." }.joined(separator: "\n")

        let url = try service.createTemporaryPDF(
            text: text,
            fontSize: 18,
            date: Date(timeIntervalSince1970: 1),
            directory: directory
        )

        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThan(document.pageCount, 1)

        let exportedText = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
        for lineNumber in 1...180 {
            XCTAssertEqual(
                exportedText.components(separatedBy: "Line \(lineNumber):").count - 1,
                1,
                "Line \(lineNumber) should appear exactly once"
            )
        }
    }

    func testLongParagraphWrapsWithoutDroppingContent() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = PDFExportService()
        let tokens = (1...600).map { String(format: "Q%04dZ", $0) }

        let url = try service.createTemporaryPDF(
            text: tokens.joined(separator: " "),
            fontSize: 18,
            date: Date(timeIntervalSince1970: 2),
            directory: directory
        )

        let document = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThan(document.pageCount, 1)
        let exportedText = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
        for token in tokens {
            XCTAssertEqual(
                exportedText.components(separatedBy: token).count - 1,
                1,
                "\(token) should appear exactly once"
            )
        }
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuartzTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
