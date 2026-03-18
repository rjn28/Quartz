import Foundation

struct EditorRoute: Hashable, Codable {
    let windowID: UUID
    let noteID: UUID
}

struct QuartzNote: Identifiable, Codable, Hashable {
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

        if let firstLine {
            return String(firstLine.prefix(40))
        }

        return "Untitled Note"
    }

    var menuTitle: String {
        "\(title) (\(Self.menuDateFormatter.string(from: updatedAt)))"
    }

    private static let menuDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

@MainActor
final class QuartzNoteLibrary: ObservableObject {
    static let shared = QuartzNoteLibrary()

    @Published private(set) var notes: [QuartzNote] = []

    var savedNotes: [QuartzNote] {
        notes.sorted { $0.updatedAt > $1.updatedAt }
    }

    private let notesKey = "Quartz.saved.notes"
    private let migrationVersionKey = "Quartz.saved.notes.migration.version"
    private let currentMigrationVersion = 1
    private let legacyTextKey = "Quartz_text_persistence"

    private init() {
        loadNotes()
        migrateLegacyNotesIfNeeded()
    }

    func makeNewRoute() -> EditorRoute {
        let note = QuartzNote()
        upsert(note, updateTimestamp: false)
        return EditorRoute(windowID: UUID(), noteID: note.id)
    }

    func makeRoute(for noteID: UUID) -> EditorRoute {
        _ = noteSnapshot(for: noteID)
        return EditorRoute(windowID: UUID(), noteID: noteID)
    }

    func noteSnapshot(for noteID: UUID) -> QuartzNote {
        if let note = notes.first(where: { $0.id == noteID }) {
            return note
        }

        let note = QuartzNote(id: noteID)
        upsert(note, updateTimestamp: false)
        return note
    }

    func saveEditorState(
        noteID: UUID,
        text: String,
        isDarkMode: Bool,
        selectedStat: TextStatType,
        fontSize: QuartzFontSize,
        isPreviewMode: Bool,
        isSplitView: Bool
    ) {
        updateNote(noteID) { note in
            note.text = text
            note.isDarkMode = isDarkMode
            note.selectedStatRawValue = selectedStat.rawValue
            note.fontSizeRawValue = Double(fontSize.rawValue)
            note.isPreviewMode = isPreviewMode
            note.isSplitView = isSplitView
        }
    }

    func canvasData(for noteID: UUID) -> Data? {
        noteSnapshot(for: noteID).canvasData
    }

    func saveCanvasData(_ data: Data?, for noteID: UUID) {
        updateNote(noteID) { note in
            note.canvasData = data
        }
    }

    private func updateNote(_ noteID: UUID, mutate: (inout QuartzNote) -> Void) {
        var note = noteSnapshot(for: noteID)
        mutate(&note)
        upsert(note, updateTimestamp: true)
    }

    private func upsert(_ note: QuartzNote, updateTimestamp: Bool) {
        var storedNote = note

        if updateTimestamp {
            storedNote.updatedAt = Date()
        }

        if let index = notes.firstIndex(where: { $0.id == storedNote.id }) {
            notes[index] = storedNote
        } else {
            notes.append(storedNote)
        }

        notes.sort { $0.updatedAt > $1.updatedAt }
        persistNotes()
    }

    private func loadNotes() {
        guard let data = UserDefaults.standard.data(forKey: notesKey) else { return }

        do {
            notes = try JSONDecoder().decode([QuartzNote].self, from: data)
            notes.sort { $0.updatedAt > $1.updatedAt }
        } catch {
            print("Error loading saved notes: \(error)")
        }
    }

    private func persistNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            UserDefaults.standard.set(data, forKey: notesKey)
        } catch {
            print("Error saving notes: \(error)")
        }
    }

    private func migrateLegacyNotesIfNeeded() {
        let defaults = UserDefaults.standard

        guard defaults.integer(forKey: migrationVersionKey) < currentMigrationVersion else { return }
        defer {
            defaults.set(currentMigrationVersion, forKey: migrationVersionKey)
        }

        guard notes.isEmpty else { return }

        var migratedNotes: [QuartzNote] = []
        let legacyWindowIDs = findLegacyWindowIDs()

        for windowID in legacyWindowIDs {
            let baseKey = "Quartz.window.\(windowID.uuidString)"
            let hasStoredState =
                defaults.object(forKey: "\(baseKey).text") != nil ||
                defaults.object(forKey: "\(baseKey).darkMode") != nil ||
                defaults.object(forKey: "\(baseKey).selectedStat") != nil ||
                defaults.object(forKey: "\(baseKey).fontSize") != nil ||
                defaults.object(forKey: "\(baseKey).previewMode") != nil ||
                defaults.object(forKey: "\(baseKey).splitView") != nil ||
                defaults.data(forKey: "\(baseKey).canvas.shapes") != nil

            guard hasStoredState else { continue }

            let note = QuartzNote(
                id: windowID,
                text: defaults.string(forKey: "\(baseKey).text") ?? "",
                isDarkMode: defaults.object(forKey: "\(baseKey).darkMode") != nil
                    ? defaults.bool(forKey: "\(baseKey).darkMode")
                    : true,
                selectedStatRawValue: defaults.string(forKey: "\(baseKey).selectedStat") ?? TextStatType.words.rawValue,
                fontSizeRawValue: {
                    let value = defaults.double(forKey: "\(baseKey).fontSize")
                    return value > 0 ? value : Double(QuartzFontSize.normal.rawValue)
                }(),
                isPreviewMode: defaults.bool(forKey: "\(baseKey).previewMode"),
                isSplitView: defaults.bool(forKey: "\(baseKey).splitView"),
                canvasData: defaults.data(forKey: "\(baseKey).canvas.shapes")
            )

            migratedNotes.append(note)
        }

        let legacyText = defaults.string(forKey: legacyTextKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !legacyText.isEmpty && !migratedNotes.contains(where: { $0.text == legacyText }) {
            migratedNotes.append(QuartzNote(text: legacyText))
        }

        if !migratedNotes.isEmpty {
            notes = migratedNotes.sorted { $0.updatedAt > $1.updatedAt }
            persistNotes()
        }
    }

    private func findLegacyWindowIDs() -> [UUID] {
        let prefix = "Quartz.window."

        let ids = UserDefaults.standard.dictionaryRepresentation().keys.compactMap { key -> UUID? in
            guard key.hasPrefix(prefix) else { return nil }

            let suffix = key.dropFirst(prefix.count)
            guard let separator = suffix.firstIndex(of: ".") else { return nil }

            return UUID(uuidString: String(suffix[..<separator]))
        }

        return Array(Set(ids))
    }
}
