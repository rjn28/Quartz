import AppKit
import CoreGraphics
import CoreText
import Foundation
import PDFKit

@MainActor
struct PDFExportService {
    private struct LaidOutLine {
        let line: CTLine
        let origin: CGPoint
        let top: CGFloat
        let bottom: CGFloat
    }

    private struct PageLayout {
        let lines: [LaidOutLine]
        let top: CGFloat
        let bottom: CGFloat
    }

    private struct DocumentLayout {
        let image: CGImage
        let imageScale: CGFloat
        let height: CGFloat
        let pages: [PageLayout]
    }

    private struct TopDownLine {
        let line: CTLine
        let x: CGFloat
        let baseline: CGFloat
        let ascent: CGFloat
        let descent: CGFloat
        let leading: CGFloat
    }

    private let fileService: NoteExportService

    init(fileService: NoteExportService = NoteExportService()) {
        self.fileService = fileService
    }

    func createTemporaryPDF(
        text: String,
        fontSize: CGFloat,
        date: Date = Date(),
        directory: URL? = nil
    ) throws -> URL {
        let directory = directory ?? fileService.fileManager.temporaryDirectory
        let url = fileService.availableURL(
            in: directory,
            baseName: "Quartz Note \(NoteExportService.timestamp(for: date))",
            pathExtension: "pdf"
        )

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let printableRect = pageRect.insetBy(dx: 40, dy: 40)
        let layout = try makeDocumentLayout(
            text: text,
            fontSize: fontSize,
            printableSize: printableRect.size
        )
        let outputDocument = PDFDocument()
        for (index, page) in layout.pages.enumerated() {
            let pageData = try renderPage(
                page: page,
                document: layout,
                pageRect: pageRect,
                printableRect: printableRect
            )
            guard let pageDocument = PDFDocument(data: pageData),
                  let renderedPage = pageDocument.page(at: 0) else {
                throw NoteExportError.pdfRenderingFailed
            }
            outputDocument.insert(renderedPage, at: index)
        }

        guard outputDocument.write(to: url),
              fileService.fileManager.fileExists(atPath: url.path) else {
            try? fileService.fileManager.removeItem(at: url)
            throw NoteExportError.pdfRenderingFailed
        }
        return url
    }

    private func makeDocumentLayout(
        text: String,
        fontSize: CGFloat,
        printableSize: CGSize
    ) throws -> DocumentLayout {
        let (lines, layoutHeight) = layoutLines(
            text: text,
            fontSize: max(8, min(fontSize, 72)),
            width: printableSize.width,
            minimumHeight: printableSize.height
        )
        guard !lines.isEmpty else {
            throw NoteExportError.pdfRenderingFailed
        }
        let pages = paginate(lines: lines, maximumHeight: printableSize.height)
        let imageScale = rasterScale(width: printableSize.width, height: layoutHeight)
        let image = try renderDocumentImage(
            lines: lines,
            size: CGSize(width: printableSize.width, height: layoutHeight),
            scale: imageScale
        )
        return DocumentLayout(
            image: image,
            imageScale: imageScale,
            height: layoutHeight,
            pages: pages
        )
    }

    private func layoutLines(
        text: String,
        fontSize: CGFloat,
        width: CGFloat,
        minimumHeight: CGFloat
    ) -> ([LaidOutLine], CGFloat) {
        var temporaryLines: [TopDownLine] = []
        var cursorY: CGFloat = 4

        for sourceLine in text.components(separatedBy: .newlines) {
            let attributedLine = styledLine(sourceLine, fontSize: fontSize, width: width)
            let paragraph = (attributedLine.attribute(
                .paragraphStyle,
                at: 0,
                effectiveRange: nil
            ) as? NSParagraphStyle) ?? NSParagraphStyle.default
            cursorY += paragraph.paragraphSpacingBefore

            var location = 0
            var isFirstVisualLine = true
            repeat {
                let indent = max(
                    0,
                    isFirstVisualLine ? paragraph.firstLineHeadIndent : paragraph.headIndent
                )
                let remainingLength = max(0, attributedLine.length - location)
                let remaining = attributedLine.attributedSubstring(
                    from: NSRange(location: location, length: remainingLength)
                )
                // A fresh typesetter keeps each wrapped line independent and deterministic.
                let typesetter = CTTypesetterCreateWithAttributedString(remaining)
                var lineLength = CTTypesetterSuggestLineBreak(
                    typesetter,
                    0,
                    max(1, width - indent)
                )
                if lineLength == 0 {
                    lineLength = min(1, remaining.length)
                }
                let line = CTTypesetterCreateLine(
                    typesetter,
                    CFRange(location: 0, length: lineLength)
                )
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                CTLineGetTypographicBounds(line, &ascent, &descent, &leading)

                var lineHeight = ascent + descent + max(0, leading)
                if paragraph.minimumLineHeight > 0 {
                    lineHeight = max(lineHeight, paragraph.minimumLineHeight)
                }
                if paragraph.maximumLineHeight > 0 {
                    lineHeight = min(lineHeight, paragraph.maximumLineHeight)
                }
                let extraHeight = max(0, lineHeight - ascent - descent)
                let baseline = cursorY + extraHeight / 2 + ascent
                temporaryLines.append(
                    TopDownLine(
                        line: line,
                        x: indent,
                        baseline: baseline,
                        ascent: ascent,
                        descent: descent,
                        leading: leading
                    )
                )

                cursorY += lineHeight
                location += lineLength
                isFirstVisualLine = false
                if location < attributedLine.length {
                    cursorY += paragraph.lineSpacing
                }
            } while location < attributedLine.length

            cursorY += paragraph.lineSpacing + paragraph.paragraphSpacing
        }

        let layoutHeight = max(minimumHeight, ceil(cursorY + 4))
        let lines = temporaryLines.map { item in
            let originY = layoutHeight - item.baseline
            let halfLeading = max(0, item.leading) / 2
            return LaidOutLine(
                line: item.line,
                origin: CGPoint(x: item.x, y: originY),
                top: originY + item.ascent + halfLeading,
                bottom: originY - item.descent - halfLeading
            )
        }
        return (lines, layoutHeight)
    }

    private func paginate(lines: [LaidOutLine], maximumHeight: CGFloat) -> [PageLayout] {
        let edgePadding: CGFloat = 2
        let usableHeight = maximumHeight - edgePadding * 2
        var pages: [PageLayout] = []
        var pageLines: [LaidOutLine] = []
        var pageTop: CGFloat = 0
        var pageBottom: CGFloat = 0

        for line in lines {
            if pageLines.isEmpty {
                pageLines = [line]
                pageTop = line.top
                pageBottom = line.bottom
                continue
            }

            if pageTop - line.bottom <= usableHeight {
                pageLines.append(line)
                pageBottom = line.bottom
            } else {
                pages.append(
                    PageLayout(
                        lines: pageLines,
                        top: pageTop + edgePadding,
                        bottom: pageBottom - edgePadding
                    )
                )
                pageLines = [line]
                pageTop = line.top
                pageBottom = line.bottom
            }
        }

        if !pageLines.isEmpty {
            pages.append(
                PageLayout(
                    lines: pageLines,
                    top: pageTop + edgePadding,
                    bottom: pageBottom - edgePadding
                )
            )
        }
        return pages
    }

    private func rasterScale(width: CGFloat, height: CGFloat) -> CGFloat {
        let maximumPixelCount: CGFloat = 32_000_000
        let maximumDimension: CGFloat = 60_000
        let memoryScale = sqrt(maximumPixelCount / max(1, width * height))
        let dimensionScale = maximumDimension / max(1, height)
        return min(2, memoryScale, dimensionScale)
    }

    private func renderDocumentImage(
        lines: [LaidOutLine],
        size: CGSize,
        scale: CGFloat
    ) throws -> CGImage {
        let pixelWidth = max(1, Int(ceil(size.width * scale)))
        let pixelHeight = max(1, Int(ceil(size.height * scale)))
        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw NoteExportError.pdfRenderingFailed
        }

        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        context.scaleBy(x: scale, y: scale)
        for item in lines {
            drawGlyphOutlines(for: item.line, at: item.origin, in: context)
        }

        guard let image = context.makeImage() else {
            throw NoteExportError.pdfRenderingFailed
        }
        return image
    }

    private func renderPage(
        page: PageLayout,
        document: DocumentLayout,
        pageRect: CGRect,
        printableRect: CGRect
    ) throws -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw NoteExportError.pdfContextCreationFailed
        }
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw NoteExportError.pdfContextCreationFailed
        }

        context.beginPDFPage(nil)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(pageRect)

        // Keep an invisible vector text layer for search, selection, and accessibility.
        context.saveGState()
        context.textMatrix = .identity
        context.setTextDrawingMode(.invisible)
        for item in page.lines {
            context.textPosition = CGPoint(
                x: printableRect.minX + item.origin.x,
                y: printableRect.maxY - page.top + item.origin.y
            )
            CTLineDraw(item.line, context)
        }
        context.restoreGState()

        let scale = document.imageScale
        let sourceY = max(0, floor((document.height - page.top) * scale))
        let sourceMaxY = min(
            CGFloat(document.image.height),
            ceil((document.height - page.bottom) * scale)
        )
        let sourceRect = CGRect(
            x: 0,
            y: sourceY,
            width: CGFloat(document.image.width),
            height: max(1, sourceMaxY - sourceY)
        )
        guard let croppedImage = document.image.cropping(to: sourceRect) else {
            context.endPDFPage()
            context.closePDF()
            throw NoteExportError.pdfRenderingFailed
        }

        let renderedHeight = min(printableRect.height, sourceRect.height / scale)
        let destination = CGRect(
            x: printableRect.minX,
            y: printableRect.maxY - renderedHeight,
            width: printableRect.width,
            height: renderedHeight
        )
        context.saveGState()
        context.interpolationQuality = .high
        context.draw(croppedImage, in: destination)
        context.restoreGState()
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }

    private func drawGlyphOutlines(
        for line: CTLine,
        at baseline: CGPoint,
        in context: CGContext
    ) {
        // CoreText specifies that CTLineGetGlyphRuns contains only CTRun values.
        let runs = CTLineGetGlyphRuns(line) as! [CTRun]
        for run in runs {
            let attributes = CTRunGetAttributes(run) as NSDictionary
            guard let font = attributes[NSAttributedString.Key.font] as? NSFont else {
                continue
            }
            let ctFont = font as CTFont
            let glyphCount = CTRunGetGlyphCount(run)
            guard glyphCount > 0 else { continue }

            var glyphs = Array(repeating: CGGlyph(), count: glyphCount)
            var positions = Array(repeating: CGPoint.zero, count: glyphCount)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)

            let runPath = CGMutablePath()
            for index in glyphs.indices {
                guard let glyphPath = CTFontCreatePathForGlyph(ctFont, glyphs[index], nil) else {
                    continue
                }
                var transform = CGAffineTransform.identity
                transform.tx += baseline.x + positions[index].x
                transform.ty += baseline.y + positions[index].y
                runPath.addPath(glyphPath, transform: transform)
            }

            let color = (attributes[NSAttributedString.Key.foregroundColor] as? NSColor) ?? .black
            context.saveGState()
            context.setFillColor(color.cgColor)
            context.addPath(runPath)
            context.fillPath()

            if let underline = attributes[NSAttributedString.Key.underlineStyle] as? NSNumber,
               underline.intValue != 0 {
                var ascent: CGFloat = 0
                var descent: CGFloat = 0
                var leading: CGFloat = 0
                let width = CGFloat(
                    CTRunGetTypographicBounds(
                        run,
                        CFRange(location: 0, length: 0),
                        &ascent,
                        &descent,
                        &leading
                    )
                )
                let underlineY = baseline.y + CTFontGetUnderlinePosition(ctFont)
                context.setStrokeColor(color.cgColor)
                context.setLineWidth(max(0.5, CTFontGetUnderlineThickness(ctFont)))
                context.move(to: CGPoint(x: baseline.x + positions[0].x, y: underlineY))
                context.addLine(to: CGPoint(x: baseline.x + positions[0].x + width, y: underlineY))
                context.strokePath()
            }
            context.restoreGState()

            if (CTFontCopyPostScriptName(ctFont) as String).contains("AppleColorEmoji") {
                context.saveGState()
                context.textMatrix = .identity
                context.textPosition = baseline
                CTRunDraw(run, context, CFRange(location: 0, length: 0))
                context.restoreGState()
            }
        }
    }

    private func styledLine(
        _ source: String,
        fontSize: CGFloat,
        width: CGFloat
    ) -> NSAttributedString {
        let trimmed = source.trimmingCharacters(in: .whitespaces)
        let descriptor: (content: String, size: CGFloat, weight: FontWeight, style: LineStyle)

        if trimmed.hasPrefix("# ") {
            descriptor = (String(trimmed.dropFirst(2)), fontSize * 2, .bold, .heading(10))
        } else if trimmed.hasPrefix("## ") {
            descriptor = (String(trimmed.dropFirst(3)), fontSize * 1.6, .bold, .heading(8))
        } else if trimmed.hasPrefix("### ") {
            descriptor = (String(trimmed.dropFirst(4)), fontSize * 1.3, .semibold, .heading(6))
        } else if trimmed.hasPrefix("> ") {
            descriptor = ("│  " + String(trimmed.dropFirst(2)), fontSize, .regular, .quote)
        } else if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
            descriptor = ("•  " + String(trimmed.dropFirst(2)), fontSize, .regular, .list)
        } else if orderedListItem(from: trimmed) != nil {
            descriptor = (trimmed, fontSize, .regular, .list)
        } else if trimmed == "---" {
            descriptor = (dividerText(fontSize: fontSize, width: width), fontSize, .regular, .divider)
        } else if trimmed.isEmpty {
            descriptor = ("\u{200B}", fontSize, .regular, .empty)
        } else {
            descriptor = (source, fontSize, .regular, .body)
        }

        let attributed = inlineMarkdown(
            descriptor.content,
            fontSize: descriptor.size,
            baseWeight: descriptor.weight
        )
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4

        switch descriptor.style {
        case let .heading(spacing):
            paragraph.paragraphSpacingBefore = spacing
            paragraph.paragraphSpacing = 2
        case .quote:
            paragraph.headIndent = fontSize
            paragraph.firstLineHeadIndent = 0
            attributed.addAttribute(
                .foregroundColor,
                value: NSColor(srgbRed: 0.32, green: 0.33, blue: 0.36, alpha: 1),
                range: attributed.fullRange
            )
            attributed.addAttribute(.obliqueness, value: 0.15, range: attributed.fullRange)
        case .list:
            paragraph.headIndent = fontSize * 1.5
            paragraph.firstLineHeadIndent = 0
        case .divider:
            paragraph.paragraphSpacingBefore = 4
            paragraph.paragraphSpacing = 4
            attributed.addAttribute(
                .foregroundColor,
                value: NSColor(srgbRed: 0.62, green: 0.63, blue: 0.66, alpha: 1),
                range: attributed.fullRange
            )
        case .empty:
            paragraph.minimumLineHeight = fontSize / 2
            paragraph.maximumLineHeight = fontSize / 2
        case .body:
            break
        }

        attributed.addAttribute(.paragraphStyle, value: paragraph, range: attributed.fullRange)
        return attributed
    }

    private func dividerText(fontSize: CGFloat, width: CGFloat) -> String {
        let dividerFont = font(size: fontSize, weight: .regular)
        let sample = NSAttributedString(string: "─", attributes: [.font: dividerFont])
        let sampleLine = CTLineCreateWithAttributedString(sample)
        let glyphWidth = max(1, CGFloat(CTLineGetTypographicBounds(sampleLine, nil, nil, nil)))
        let count = max(1, Int(floor((width - 4) / glyphWidth)))
        return String(repeating: "─", count: count)
    }

    private func inlineMarkdown(
        _ source: String,
        fontSize: CGFloat,
        baseWeight: FontWeight
    ) -> NSMutableAttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        let parsed = (try? AttributedString(markdown: source, options: options)) ?? AttributedString(source)
        let result = NSMutableAttributedString(attributedString: NSAttributedString(parsed))
        if result.length == 0 {
            result.append(NSAttributedString(string: "\u{200B}"))
        }
        let range = result.fullRange
        result.addAttributes(
            [
                .font: font(size: fontSize, weight: baseWeight),
                .foregroundColor: NSColor.black
            ],
            range: range
        )

        let intentKey = NSAttributedString.Key("NSInlinePresentationIntent")
        result.enumerateAttribute(intentKey, in: range) { value, subrange, _ in
            let rawValue = (value as? NSNumber)?.intValue ?? (value as? Int) ?? 0
            let isItalic = rawValue & 1 != 0
            let isBold = rawValue & 2 != 0
            let isCode = rawValue & 4 != 0

            if isCode {
                result.addAttribute(.font, value: monospacedFont(size: fontSize * 0.92), range: subrange)
            } else {
                let weight: FontWeight = isBold ? .bold : baseWeight
                result.addAttribute(
                    .font,
                    value: font(size: fontSize, weight: weight, italic: isItalic),
                    range: subrange
                )
            }
        }

        result.enumerateAttribute(.link, in: range) { value, subrange, _ in
            guard value != nil else { return }
            result.addAttributes(
                [
                    .foregroundColor: NSColor(srgbRed: 0.05, green: 0.32, blue: 0.78, alpha: 1),
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ],
                range: subrange
            )
        }
        return result
    }

    private enum FontWeight {
        case regular
        case semibold
        case bold
    }

    private enum LineStyle {
        case body
        case heading(CGFloat)
        case quote
        case list
        case divider
        case empty
    }

    private func font(
        size: CGFloat,
        weight: FontWeight,
        italic: Bool = false
    ) -> NSFont {
        let name: String
        switch (weight, italic) {
        case (.regular, false): name = "AvenirNext-Regular"
        case (.regular, true): name = "AvenirNext-Italic"
        case (.semibold, false): name = "AvenirNext-DemiBold"
        case (.semibold, true): name = "AvenirNext-DemiBoldItalic"
        case (.bold, false): name = "AvenirNext-Bold"
        case (.bold, true): name = "AvenirNext-BoldItalic"
        }
        return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
    }

    private func monospacedFont(size: CGFloat) -> NSFont {
        NSFont(name: "Menlo-Regular", size: size) ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
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
}

private extension NSAttributedString {
    var fullRange: NSRange { NSRange(location: 0, length: length) }
}
