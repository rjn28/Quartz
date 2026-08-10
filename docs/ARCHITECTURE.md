# Quartz Architecture

## Goals

Quartz is a native, local-first macOS editor. The architecture prioritizes data durability, predictable multi-window behavior, accessibility, small dependency surface, and a release artifact users can verify.

## Source layout

```text
Sources/Quartz/
├── App/          scene and command registration
├── Models/       persisted and pure value types
├── Services/     TXT/PDF export and platform boundaries
├── Stores/       note persistence and migrations
├── Support/      focused command routing
├── ViewModels/   editor and canvas state coordination
├── Views/        focused SwiftUI view types
└── Resources/    app assets

Tests/QuartzTests/
└── unit, persistence, migration, and export tests
```

## State ownership

| State | Owner | Lifetime |
| --- | --- | --- |
| Text, canvas, note metadata | `QuartzNoteLibrary` | Persisted per note |
| Editor mode, theme, font size, statistic | `QuartzViewModel` | Loaded from and saved with the note |
| Current shape, undo/redo, text-entry overlay | `DrawingCanvasViewModel` | Canvas session, with persisted completed shapes |
| Canvas presentation, Zen controls, alerts | `ContentView` | Window-local and ephemeral |
| Saved-note menu | `QuartzNoteLibrary.shared` | Application-wide |

`EditorRoute` is keyed only by `noteID`. Opening an already-open saved note therefore targets the same typed SwiftUI window value instead of creating two stale editor snapshots that can overwrite one another.

## Persistence

`QuartzNoteLibrary` is a `@MainActor` observable store backed by the app's `UserDefaults` domain. It:

- removes content-free records;
- preserves an undecodable modern blob under a recovery key before accepting new writes;
- flushes editor and canvas state explicitly when their views disappear;
- keeps legacy data until migrations have persisted successfully;
- performs idempotent migrations.

Migration versions:

1. Global text and earlier per-window state are converted to saved notes.
2. The `Quartz_canvas_shapes` data written by public release `v1.2` is attached to the matching migrated note or preserved as a canvas-only note.

The current single-blob design remains appropriate only for a modest note library. Moving to independently encoded atomic files is a tracked priority because one large canvas or many notes can make main-actor encoding expensive.

## Rendering and interaction

- `WindowGroup` uses a non-optional `defaultValue`, so the first scene receives a stable codable route.
- `EditorMode` replaces invalid combinations of preview/split booleans in live state while the persisted booleans remain backward compatible.
- `HSplitView` provides native resizable editor/preview panes.
- Focused values route window-specific commands from the menu bar.
- Zen controls use cancellable main-actor tasks and `onContinuousHover`; no application-wide AppKit event monitor is installed.
- The app propagates `preferredColorScheme`, while drawing colors use an explicit named palette.

## Export boundary

`NoteExportService` owns deterministic filenames, collision avoidance, text writes, and Desktop copies. `PDFExportService` parses inline Markdown, typesets wrapped lines independently, and emits standard 595 × 842 point pages with line-safe visual crops plus a selectable text layer. This keeps long exports deterministic while preserving search and accessibility.

All export APIs throw. The UI reports failure instead of returning invalid URLs or swallowing file-system errors. Drag providers never use force unwraps.

## Packaging boundary

`scripts/package_app.sh` builds both `arm64` and `x86_64`, assembles the app in an isolated temporary directory, injects the tracked version and monotonic build number, creates the icon, signs, verifies architectures and signature, creates the DMG, verifies it, and prints SHA-256.

An ad hoc signature is allowed only for local testing. The GitHub release workflow requires Developer ID signing, hardened runtime, notarization, stapling, checksum generation, provenance attestation, and a signed tag.

## Known architectural follow-ups

- Drawing points are absolute rather than normalized to the canvas size.
- UserDefaults persistence still encodes the complete library as one blob.
- There are unit and export tests but no end-to-end UI automation yet.
- The custom non-commercial license is intentionally treated as a pending product/governance decision.
