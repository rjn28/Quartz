# Changelog

All notable changes to Quartz are documented here. The project follows [Semantic Versioning](https://semver.org/) from `v1.3.0` onward.

## Unreleased

### Added

- SwiftPM test target with coverage for statistics, persistence, migrations, drawing geometry, view models, TXT export, and paginated PDF export.
- GitHub Actions CI, CodeQL analysis, pinned actions, Dependabot updates, and a fail-closed signed/notarized release workflow.
- Contributor, security, support, conduct, architecture, release, roadmap, and project-audit documentation.
- Keyboard commands, VoiceOver labels, drawing redo, export feedback, and recoverable corrupt-canvas handling.

### Changed

- Migrated to a standard SwiftPM `Sources/` and `Tests/` layout with Swift tools 6.0.
- Reworked editor state around an invariant editor mode and stable per-note window identity.
- Made the split editor resizable and the control surfaces responsive.
- Centralized versioning and replaced the destructive packaging script with validated universal packaging.
- Updated project terminology from “open source” to “source-available” to match the current license.

### Fixed

- Migrates the global canvas data written by public release `v1.2`, including users who already ran the earlier v1 migration.
- Flushes pending text and canvas state during view teardown and when the app scene becomes inactive.
- Prevents duplicate windows from independently overwriting the same note.
- Preserves a recovery copy when the saved-note blob cannot be decoded.
- Reports export failures, avoids filename collisions and force unwraps, and paginates long PDFs.
- Corrects square geometry for negative drag directions and avoids theme-dependent invisible ink.

## 1.2.0 - 2026-01-16

- Added the drawing canvas.

Published under tag `v1.2`; the tag and embedded bundle version predate the standardized release process.

## 1.1.0 - 2026-01-07

- Added Markdown preview and split view.

Published under tag `v1.1`; the tag and embedded bundle version predate the standardized release process.

## 1.0.0 - 2025-12-03

- Initial public release of the focused text editor and drag export.
