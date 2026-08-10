import Combine
import Foundation
import os

@MainActor
final class QuartzNoteLibrary: ObservableObject {
    enum StorageKeys {
        static let notes = "Quartz.saved.notes"
        static let corruptedNotesBackup = "Quartz.saved.notes.corrupted-backup"
        static let migrationVersion = "Quartz.saved.notes.migration.version"
        static let legacyText = "Quartz_text_persistence"
        static let legacyCanvas = "Quartz_canvas_shapes"
    }

    static let shared = QuartzNoteLibrary()

    @Published private(set) var notes: [QuartzNote] = []

    var savedNotes: [QuartzNote] { notes }

    private let defaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let now: () -> Date
    private let logger = Logger(subsystem: "com.rjn28.Quartz", category: "NoteLibrary")
    private let currentMigrationVersion = 2

    init(
        defaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.encoder = encoder
        self.decoder = decoder
        self.now = now

        loadNotes()
        removeEmptyNotesIfNeeded()
        migrateLegacyNotesIfNeeded()
        removeEmptyNotesIfNeeded()
    }

    func makeNewRoute() -> EditorRoute {
        EditorRoute(noteID: UUID())
    }

    func makeRoute(for noteID: UUID) -> EditorRoute {
        EditorRoute(noteID: noteID)
    }

    func noteSnapshot(for noteID: UUID) -> QuartzNote {
        if let note = notes.first(where: { $0.id == noteID }) {
            return note
        }

        let timestamp = now()
        return QuartzNote(id: noteID, createdAt: timestamp, updatedAt: timestamp)
    }

    func saveEditorState(
        noteID: UUID,
        text: String,
        isDarkMode: Bool,
        selectedStat: TextStatType,
        fontSize: QuartzFontSize,
        editorMode: EditorMode
    ) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingCanvasData = notes.first(where: { $0.id == noteID })?.canvasData

        if trimmedText.isEmpty && existingCanvasData?.isEmpty != false {
            removeNote(noteID)
            return
        }

        updateNote(noteID) { note in
            note.text = text
            note.isDarkMode = isDarkMode
            note.selectedStatRawValue = selectedStat.rawValue
            note.fontSizeRawValue = Double(fontSize.rawValue)
            note.isPreviewMode = editorMode.isPreviewMode
            note.isSplitView = editorMode.isSplitView
        }
    }

    func canvasData(for noteID: UUID) -> Data? {
        notes.first(where: { $0.id == noteID })?.canvasData
    }

    func saveCanvasData(_ data: Data?, for noteID: UUID) {
        let normalizedData = data?.isEmpty == false ? data : nil
        let existingText = notes.first(where: { $0.id == noteID })?.text ?? ""
        let hasText = !existingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if normalizedData == nil && !hasText {
            removeNote(noteID)
            return
        }

        updateNote(noteID) { note in
            note.canvasData = normalizedData
        }
    }

    private func updateNote(_ noteID: UUID, mutate: (inout QuartzNote) -> Void) {
        var note = noteSnapshot(for: noteID)
        mutate(&note)
        note.updatedAt = now()

        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        } else {
            notes.append(note)
        }

        notes.sort { $0.updatedAt > $1.updatedAt }
        persistNotes()
    }

    private func removeNote(_ noteID: UUID) {
        let previousCount = notes.count
        notes.removeAll { $0.id == noteID }

        if notes.count != previousCount {
            persistNotes()
        }
    }

    private func loadNotes() {
        guard let data = defaults.data(forKey: StorageKeys.notes) else { return }

        do {
            notes = try decoder.decode([QuartzNote].self, from: data)
            notes.sort { $0.updatedAt > $1.updatedAt }
        } catch {
            if defaults.data(forKey: StorageKeys.corruptedNotesBackup) == nil {
                defaults.set(data, forKey: StorageKeys.corruptedNotesBackup)
            }
            logger.error("Unable to decode saved notes; preserved a recovery copy: \(error.localizedDescription, privacy: .public)")
        }
    }

    @discardableResult
    private func persistNotes() -> Bool {
        do {
            defaults.set(try encoder.encode(notes), forKey: StorageKeys.notes)
            return true
        } catch {
            logger.error("Unable to encode saved notes: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func removeEmptyNotesIfNeeded() {
        let previousCount = notes.count
        notes.removeAll { !$0.hasContent }

        if notes.count != previousCount {
            persistNotes()
        }
    }

    private func migrateLegacyNotesIfNeeded() {
        var version = defaults.integer(forKey: StorageKeys.migrationVersion)

        if version < 1 {
            guard migrateLegacyWindowAndTextData() else { return }
            defaults.set(1, forKey: StorageKeys.migrationVersion)
            version = 1
        }

        if version < 2 {
            guard migrateLegacyGlobalCanvas() else { return }
            defaults.set(2, forKey: StorageKeys.migrationVersion)
            version = 2
        }

        assert(version == currentMigrationVersion)
    }

    private func migrateLegacyWindowAndTextData() -> Bool {
        guard notes.isEmpty else { return true }

        var migratedNotes = findLegacyWindowIDs().compactMap(makeLegacyNote(for:))
        let legacyText = defaults.string(forKey: StorageKeys.legacyText)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !legacyText.isEmpty && !migratedNotes.contains(where: { $0.text == legacyText }) {
            let timestamp = now()
            migratedNotes.append(
                QuartzNote(createdAt: timestamp, updatedAt: timestamp, text: legacyText)
            )
        }

        guard !migratedNotes.isEmpty else { return true }
        notes = migratedNotes.sorted { $0.updatedAt > $1.updatedAt }
        return persistNotes()
    }

    private func migrateLegacyGlobalCanvas() -> Bool {
        guard let canvasData = defaults.data(forKey: StorageKeys.legacyCanvas),
              !canvasData.isEmpty else {
            return true
        }

        guard !notes.contains(where: { $0.canvasData == canvasData }) else {
            return true
        }

        let legacyText = defaults.string(forKey: StorageKeys.legacyText) ?? ""
        let matchingIndex = notes.firstIndex(where: { $0.text == legacyText && $0.canvasData == nil })
        let onlyNoteIndex = notes.count == 1 && notes[0].canvasData == nil ? 0 : nil

        if let index = matchingIndex ?? onlyNoteIndex {
            notes[index].canvasData = canvasData
            notes[index].updatedAt = now()
        } else {
            let timestamp = now()
            notes.append(
                QuartzNote(
                    createdAt: timestamp,
                    updatedAt: timestamp,
                    canvasData: canvasData
                )
            )
        }

        notes.sort { $0.updatedAt > $1.updatedAt }
        return persistNotes()
    }

    private func makeLegacyNote(for windowID: UUID) -> QuartzNote? {
        let baseKey = "Quartz.window.\(windowID.uuidString)"
        let keys = [
            "text", "darkMode", "selectedStat", "fontSize", "previewMode", "splitView", "canvas.shapes"
        ]

        guard keys.contains(where: { defaults.object(forKey: "\(baseKey).\($0)") != nil }) else {
            return nil
        }

        let storedFontSize = defaults.double(forKey: "\(baseKey).fontSize")
        let timestamp = now()
        return QuartzNote(
            id: windowID,
            createdAt: timestamp,
            updatedAt: timestamp,
            text: defaults.string(forKey: "\(baseKey).text") ?? "",
            isDarkMode: defaults.object(forKey: "\(baseKey).darkMode") == nil ||
                defaults.bool(forKey: "\(baseKey).darkMode"),
            selectedStatRawValue: defaults.string(forKey: "\(baseKey).selectedStat") ??
                TextStatType.words.rawValue,
            fontSizeRawValue: storedFontSize > 0 ?
                storedFontSize : Double(QuartzFontSize.normal.rawValue),
            isPreviewMode: defaults.bool(forKey: "\(baseKey).previewMode"),
            isSplitView: defaults.bool(forKey: "\(baseKey).splitView"),
            canvasData: defaults.data(forKey: "\(baseKey).canvas.shapes")
        )
    }

    private func findLegacyWindowIDs() -> [UUID] {
        let prefix = "Quartz.window."
        let ids = defaults.dictionaryRepresentation().keys.compactMap { key -> UUID? in
            guard key.hasPrefix(prefix) else { return nil }
            let suffix = key.dropFirst(prefix.count)
            guard let separator = suffix.firstIndex(of: ".") else { return nil }
            return UUID(uuidString: String(suffix[..<separator]))
        }

        return Array(Set(ids))
    }
}
