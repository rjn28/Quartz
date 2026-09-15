<p align="center">
  <img src="docs/quartz-logo.webp" width="96" height="96" alt="Quartz app icon">
</p>

<h1 align="center">Quartz</h1>
<p align="center"><strong>Write. Breathe. Repeat.</strong></p>
<p align="center">A quiet room for your mind. A native writing canvas for your Mac.</p>

<p align="center">
  <strong>English</strong> · <a href="README.fr.md">Français</a>
</p>

<p align="center">
  <a href="https://github.com/rjn28/Quartz/releases/latest"><img src="docs/buttons/download-en.svg" height="48" alt="Download Quartz for macOS"></a>
  <a href="#documentation"><img src="docs/buttons/docs-en.svg" height="48" alt="Read the documentation"></a>
  <a href="ROADMAP.md"><img src="docs/buttons/roadmap-en.svg" height="48" alt="Explore the roadmap"></a>
</p>

<p align="center">
  <img alt="macOS 14 or later, Apple Silicon" src="https://img.shields.io/badge/macOS-14%2B%20%C2%B7%20Apple%20Silicon-242938?logo=apple&amp;logoColor=white">
  <a href="https://github.com/rjn28/Quartz/actions/workflows/ci.yml"><img alt="CI status" src="https://github.com/rjn28/Quartz/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/rjn28/Quartz/actions/workflows/codeql.yml"><img alt="CodeQL status" src="https://github.com/rjn28/Quartz/actions/workflows/codeql.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="Apache License 2.0" src="https://img.shields.io/badge/License-Apache--2.0-7963DC"></a>
</p>

---

## The Art of Focus

> Creativity isn't about adding things. It's about subtracting the noise until only the essential remains.

Quartz gives your words room to breathe. Write a note, see your Markdown take shape, or open a canvas to sketch an idea. Your work stays on your Mac, without an account, cloud sync, analytics, or a required connection.

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/markdown-dark.jpg">
    <source media="(prefers-color-scheme: light)" srcset="docs/screenshots/markdown-light.jpg">
    <img src="docs/screenshots/markdown-light.jpg" width="960" alt="Quartz with the original The Art of Focus text on the left and its rendered Markdown preview on the right">
  </picture>
  <br>
  <sub>Write on the left. See it take shape on the right. Markdown split view in light or dark appearance.</sub>
</p>

## A little space. A lot of possibility.

| | Made for the way you think |
| :--- | :--- |
| **✍️ Stay with the thought** | A focused editor whose controls fade while you type. Adjust the text size and switch between light and dark appearances. |
| **◧ See your words take shape** | Markdown preview, editor-only mode, and a resizable split view. |
| **✏️ Think beyond text** | A canvas for each note, with lines, circles, squares, rectangles, text, colors, undo, and redo. |
| **▤ Keep an idea close** | Saved-note history and independent macOS windows, with settings remembered for each note. |
| **↗ Take it with you** | Click or drag to export text as TXT or a paginated PDF, depending on the editor mode. |
| **⌘ Make yourself at home** | Keyboard commands, VoiceOver labels, and word, character, line, and reading-time statistics. |

### Your space, light or dark

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/screenshots/editor-dark.jpg">
    <source media="(prefers-color-scheme: light)" srcset="docs/screenshots/editor-light.jpg">
    <img src="docs/screenshots/editor-light.jpg" width="800" alt="Quartz editor with the original The Art of Focus text and controls hidden while writing">
  </picture>
  <br>
  <sub>The same quiet space, in light or dark appearance. Screenshots captured manually in Quartz.</sub>
</p>

<details>
<summary><strong>The original inspiration</strong></summary>

The original screenshot and its words remain part of Quartz's story.

> The best ideas don't come from busy work. They come from stillness.

<img src="docs/screenshot_ui.png" width="100%" alt="Original Quartz interface and The Art of Focus text, ending with Write. Breathe. Repeat.">

</details>

## Get Quartz

**macOS 14 Sonoma or later · Apple Silicon (M-series).** Intel Macs are not supported.

1. Download the `.dmg` from the [latest release](https://github.com/rjn28/Quartz/releases/latest).
2. Open the disk image and drag **Quartz** into **Applications**.
3. Launch Quartz and start writing.

**[v1.3.0](https://github.com/rjn28/Quartz/releases/tag/v1.3.0) is available:** Developer ID-signed, notarized by Apple, and distributed with a SHA-256 checksum and GitHub build provenance attestation. The public build's installation and launch were confirmed on the maintainer's Mac; broader manual acceptance is tracked in the [test tracker](docs/TEST_TRACKER.md).

<details>
<summary><strong>Verify your download</strong></summary>

Download both `Quartz-1.3.0.dmg` and `Quartz-1.3.0.dmg.sha256` from the [same release](https://github.com/rjn28/Quartz/releases/tag/v1.3.0). In the folder containing both files, run:

```bash
shasum -a 256 -c Quartz-1.3.0.dmg.sha256
gh attestation verify Quartz-1.3.0.dmg --repo rjn28/Quartz
```

The second command requires the GitHub CLI. For another version, use the matching filenames. Releases before `v1.3.0` are legacy ad hoc-signed builds and were not notarized.

</details>

## What's new

The **1.3.0 release** brings the modern Swift 6 foundation, a resizable split editor, drawing redo, keyboard commands, VoiceOver labels, and more reliable note persistence and paginated PDF exports. Quartz is now licensed under **Apache-2.0**.

Since that release, the project has recorded public-build verification, planned a separate Mac App Store distribution, and updated CodeQL automation. **Mac App Store availability and automatic updates are still planned.**

[Full changelog](CHANGELOG.md) · [What's next](ROADMAP.md) · [Mac App Store plan](docs/MAC_APP_STORE.md)

## At your fingertips

| Shortcut | Action |
| :--- | :--- |
| `⌘ N` | New note window |
| `⌘ 0` | Show controls |
| `⌘ 1` / `⌘ 2` / `⌘ 3` | Editor / preview / split view |
| `⌘ ⇧ D` | Toggle drawing canvas |
| `⌘ Z` / `⌘ ⇧ Z` | Undo / redo in the drawing canvas |

Find saved notes in **Notes → Saved Notes**. In editor mode, the export button produces **TXT**; in preview or split mode, it produces **PDF**. Click to save to the Desktop, or drag the button to a destination.

## Your notes stay with you

Quartz stores note metadata, text, and drawing data in the current macOS user's local preferences (`UserDefaults`, domain `com.rjn28.Quartz`). Exports are created on request. Quartz does not send your content to a server.

Local storage is not an encrypted vault or a backup service. Before testing migrations or unreleased builds with important notes, back up the app's preferences. Independently stored, atomic note records are on the [roadmap](ROADMAP.md).

## Build from source

Use an Apple Silicon Mac with **macOS 14+** and **Xcode Command Line Tools with Swift 6**. Quartz uses Swift Package Manager and has no third-party package dependencies.

```bash
git clone https://github.com/rjn28/Quartz.git
cd Quartz
./scripts/build_and_run.sh --verify
```

The script builds Quartz, stages a local `.app` bundle in `dist/`, launches it, and checks that its process is running.

| Command | Purpose |
| :--- | :--- |
| `./scripts/check.sh` | Strict-concurrency build with warnings as errors, tests, release build, and diff checks |
| `swift test` | Run the automated tests |
| `./scripts/package_app.sh` | Create a local Apple Silicon DMG in `BuildArtifacts/` |

Without `CODE_SIGN_IDENTITY`, local packaging uses an ad hoc signature for testing. See the [release guide](docs/RELEASING.md) for public distribution, signing, and notarization.

## Documentation

| Discover | Build & contribute | Project health |
| :--- | :--- | :--- |
| [Changelog](CHANGELOG.md) | [Architecture](docs/ARCHITECTURE.md) | [Audit & improvement tracker](docs/PROJECT_AUDIT.md) |
| [Roadmap](ROADMAP.md) | [Contributing](CONTRIBUTING.md) | [Manual tests & release acceptance](docs/TEST_TRACKER.md) |
| [Support](SUPPORT.md) | [Release process](docs/RELEASING.md) | [Security policy](SECURITY.md) |
| [Mac App Store plan](docs/MAC_APP_STORE.md) | [Code of conduct](CODE_OF_CONDUCT.md) | [Maintainers](MAINTAINERS.md) |

Bug reports and focused pull requests are welcome. [Report a bug or suggest an idea](https://github.com/rjn28/Quartz/issues/new/choose), and read the [contribution guide](CONTRIBUTING.md) before starting. Report vulnerabilities privately through the [security policy](SECURITY.md).

---

<p align="center">
  Open source under <a href="LICENSE">Apache License 2.0</a> · Made by <a href="https://github.com/rjn28">Roch Junior Nicolas</a><br>
  <sub>Write. Breathe. Repeat.</sub>
</p>
