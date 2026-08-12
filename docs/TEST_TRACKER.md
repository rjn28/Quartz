# Quartz Test Tracker

> Living record for automated validation, manual acceptance testing, and release readiness.
>
> Last updated: 2026-08-13
>
> Current tested commit: `a093140` (`v1.3.0`, public release)
>
> Maintainer acceptance testing: in progress

## How to use this tracker

This file is the source of truth for test progress over time. A manual test remains `NOT RUN` until the maintainer explicitly reports its outcome; automated checks do not count as maintainer acceptance.

When asking “where are we with testing?” (or “où en est-on des tests ?”), Quartz maintainers should:

1. read this file;
2. report the totals by status and the current blockers;
3. recommend the next smallest useful test;
4. update the relevant row and append a session-log entry after a result is reported.

Natural-language reports are enough. For example: “MAN-003 passed on macOS 15.6” or “the long PDF test failed because page 3 duplicated a line.” Record the result only when the tested build and observed outcome are clear; otherwise ask for the missing detail.

## Status legend

| Status | Meaning |
| --- | --- |
| `NOT RUN` | No maintainer result has been recorded for the current release candidate. |
| `PASS` | Observed result matches the expected result. |
| `FAIL` | A reproducible mismatch or regression was observed. |
| `BLOCKED` | The test cannot run because a prerequisite or artifact is unavailable. |
| `RETEST` | It previously ran, but a relevant change requires another pass. |

If a test fails, keep it `FAIL` until the fix is verified. Link the issue or pull request in the Evidence/notes column when one exists.

## Current snapshot

| Test set | PASS | FAIL | NOT RUN | BLOCKED | RETEST |
| --- | ---: | ---: | ---: | ---: | ---: |
| Automated baseline | 10 | 0 | 0 | 0 | 0 |
| Maintainer manual acceptance | 1 | 0 | 22 | 1 | 0 |

Quartz `v1.3.0` is public, signed, notarized, and automatically verified. Maintainer acceptance remains incomplete: the real v1.2 migration and a clean-Mac install are the highest-priority manual checks.

## Test environment

Complete or add a row for each materially different environment used. Never replace an older row that supports a recorded result.

| Environment ID | Mac | Chip | macOS | Display / accessibility settings | Notes |
| --- | --- | --- | --- | --- | --- |
| `ENV-001` | _To record_ | Apple Silicon | _To record_ | _To record_ | Primary maintainer environment |

Quartz intentionally supports Apple Silicon only. An Intel result is out of scope rather than a failure.

## Automated baseline

These checks were executed during the modernization work. Re-run `./scripts/check.sh` after code changes; CI remains the authoritative check for pull requests.

| ID | Check | Result | Date | Commit / evidence |
| --- | --- | --- | --- | --- |
| `AUTO-001` | Swift 6 strict-concurrency build with warnings as errors | `PASS` | 2026-08-10 | Local `./scripts/check.sh` |
| `AUTO-002` | XCTest suite | `PASS` (28/28) | 2026-08-10 | Local `swift test` |
| `AUTO-003` | Release build | `PASS` | 2026-08-10 | Local `swift build -c release` |
| `AUTO-004` | Apple Silicon DMG packaging and bundle inspection | `PASS` | 2026-08-10 | `arm64`, macOS 14+, version 1.3.0 |
| `AUTO-005` | GitHub CI on merged `main` | `PASS` | 2026-08-10 | [CI run 31418712057](https://github.com/rjn28/Quartz/actions/runs/31418712057) |
| `AUTO-006` | CodeQL Swift analysis on merged `main` | `PASS` | 2026-08-10 | [CodeQL run 31418711189](https://github.com/rjn28/Quartz/actions/runs/31418711189) |
| `AUTO-007` | Code/dependency/secret alert review | `PASS` (0 open) | 2026-08-10 | GitHub CodeQL, Dependabot, and secret scanning |
| `AUTO-008` | Developer ID signature and Apple notarization preflight | `PASS` | 2026-08-13 | Apple submission `af8a2581-ceec-4fdb-a6bf-d79644f47162`; no issues; stapled DMG and embedded app accepted by Gatekeeper |
| `AUTO-009` | Protected release workflow | `PASS` | 2026-08-13 | [Release run 31652290027](https://github.com/rjn28/Quartz/actions/runs/31652290027); signed tag, exact `main` commit, tests, signing, notarization, checksum, attestation, and publication |
| `AUTO-010` | Public `v1.3.0` artifact verification | `PASS` | 2026-08-13 | SHA-256 and GitHub attestation verified; stapled DMG/app accepted by Gatekeeper; Developer ID team `KZET75GDV4`; `arm64`; version `1.3.0 (1001)` |

## Maintainer manual acceptance

Use a disposable note unless the procedure explicitly requires legacy data. Record the environment, date, build/commit, and concise evidence for every result.

| ID | Area | Procedure and expected result | Status | Last run | Environment | Evidence / notes |
| --- | --- | --- | --- | --- | --- | --- |
| `MAN-001` | Launch from source | Run `./scripts/build_and_run.sh --verify`; Quartz launches from the locally built bundle without a crash. | `PASS` | 2026-08-11 | macOS / Apple Silicon | Locally built bundle launched and its exact process path was verified. |
| `MAN-002` | Editing and statistics | Create a note, enter ASCII, accented text, emoji, blank lines, and Markdown; text remains responsive and statistics update plausibly. | `NOT RUN` | — | — | — |
| `MAN-003` | Immediate-quit durability | Type a unique final phrase and immediately press Command-Q; relaunch and confirm the entire phrase was saved. | `NOT RUN` | — | — | — |
| `MAN-004` | Saved-note history | Create at least three titled notes, reopen each from Saved Texts, then delete the contents of a text-only note; titles and removal behavior are correct. | `NOT RUN` | — | — | — |
| `MAN-005` | Multiple distinct windows | Open two different notes in separate windows, edit both, close and reopen them; neither note overwrites the other. | `NOT RUN` | — | — | — |
| `MAN-006` | Same-note routing | Try to open the same saved note again; Quartz reuses/deduplicates its note identity instead of creating competing stale copies. | `NOT RUN` | — | — | — |
| `MAN-007` | Per-note preferences | Give two notes different theme, font size, and editor mode settings; switch/relaunch and confirm each note restores its own values. | `NOT RUN` | — | — | — |
| `MAN-008` | Editor layouts | Exercise Editor, Preview, and Split using controls and Command-1/2/3; resize the split and window without overlap or unusable controls. | `NOT RUN` | — | — | — |
| `MAN-009` | Drawing tools | Draw freehand lines, rectangles, squares in all drag directions, circles, arrows, and text in several colors; geometry and contrast remain correct. | `NOT RUN` | — | — | — |
| `MAN-010` | Canvas durability | Add a distinctive stroke and immediately close the window or quit; reopen the note and confirm the complete drawing remains. | `NOT RUN` | — | — | — |
| `MAN-011` | Canvas undo/redo/reset | Undo and redo several shapes, clear the canvas, and confirm the controls and saved state match what is visible. | `NOT RUN` | — | — | — |
| `MAN-012` | TXT export | Export the same note twice by click and by dragging to Finder; files have unique names and exact UTF-8 content. | `NOT RUN` | — | — | — |
| `MAN-013` | Styled PDF export | Export headings, body text, a quote, `---`, Unicode, and the empty Markdown link `[]()`; the PDF does not crash and every style is visible on white pages. | `NOT RUN` | — | — | — |
| `MAN-014` | Long PDF export | Export at least 180 uniquely numbered lines; verify A4 pagination, continuous numbering with no duplicates/cuts, and searchable/selectable text. | `NOT RUN` | — | — | — |
| `MAN-015` | Light/dark appearance | Test Quartz light and dark themes while macOS uses both appearances; text, drawing ink, controls, preview, and exports remain legible. | `NOT RUN` | — | — | — |
| `MAN-016` | Keyboard and Zen Mode | Test mode shortcuts, drawing undo/redo, Escape/Return where applicable, and Zen Mode; focus and controls remain recoverable. | `NOT RUN` | — | — | — |
| `MAN-017` | VoiceOver | Navigate the editor, mode controls, statistics, drawing tools/colors, saved notes, and export actions; labels and selected values are understandable. | `NOT RUN` | — | — | — |
| `MAN-018` | Reduce Motion | Enable Reduce Motion in macOS and repeat control reveal/hide and mode changes; no unnecessary animation or loss of state occurs. | `NOT RUN` | — | — | — |
| `MAN-019` | Local DMG | Mount `BuildArtifacts/Quartz-1.3.0.dmg`, copy the app, and inspect/launch it for local testing; record any expected ad hoc Gatekeeper warning separately from app defects. | `NOT RUN` | — | — | — |
| `MAN-020` | Offline/privacy smoke test | Disable networking, edit/draw/relaunch/export, and confirm all core functions work; Quartz should require no account or network. | `NOT RUN` | — | — | — |
| `ADV-001` | Real v1.2 migration | On a backup or disposable macOS account, load copied real v1.2 preferences, launch 1.3.0, and verify legacy text and canvas survive together. Do not use the only copy of important data. | `NOT RUN` | — | — | Requires a real v1.2 fixture |
| `ADV-002` | Recovery behavior | On a disposable preferences domain, introduce a corrupted library blob and verify Quartz quarantines it instead of silently overwriting recoverable data. | `NOT RUN` | — | — | Run with developer guidance |
| `REL-001` | Notarized clean install | Download `v1.3.0` on a clean Apple Silicon Mac; checksum, attestation, Gatekeeper, notarization ticket, install, and first launch all pass. | `NOT RUN` | — | — | Public artifact is available; automated integrity and trust checks passed on the primary Mac |
| `REL-002` | Sparkle update | Upgrade between two notarized versions through a signed HTTPS appcast; signature failure and rollback behavior are fail-closed. | `BLOCKED` | — | — | Sparkle is intentionally deferred until after first notarized release |

## Suggested execution order

To make progress without turning testing into a single long session:

1. `MAN-001` through `MAN-004`: launch and basic data safety;
2. `MAN-005` through `MAN-011`: windows, per-note state, and canvas;
3. `MAN-012` through `MAN-016`: exports and daily interaction;
4. `MAN-017` through `MAN-020`: accessibility, appearance, and privacy;
5. `ADV-001` and `ADV-002`: guarded migration/recovery exercises;
6. `REL-001` and `REL-002`: only when their release prerequisites exist.

Stop normal testing after a data-loss, launch-crash, or reproducible export-corruption failure. Preserve the affected preferences/export and open a defect before continuing destructive scenarios.

## Session log

Append one row per test session, even if no case completes. Keep concise detail in the matrix and link longer evidence from Notes/issues.

| Date/time | Environment | Build / commit | Tests attempted | Outcome summary | Issues / evidence |
| --- | --- | --- | --- | --- | --- |
| — | — | — | — | Maintainer acceptance not started | — |

## Release acceptance rule

A release candidate is ready for public release only when:

- all applicable `MAN-*` cases are `PASS` on a supported Apple Silicon environment;
- `ADV-001` passes against a real copied v1.2 fixture;
- no `FAIL` or `RETEST` item remains;
- automated CI and CodeQL pass on the exact release commit;
- `REL-001` passes for the notarized artifact;
- checksum and GitHub attestation verification instructions are confirmed against the published files.

`REL-002` is not required for the first notarized release because Sparkle is deliberately scheduled afterward.
