# Contributing to Quartz

Thank you for helping improve Quartz. Keep changes focused, testable, and consistent with the native macOS experience.

## Before you start

- Search existing issues and pull requests.
- Use the bug or feature issue form for user-visible work.
- For security-sensitive findings, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
- Large product or persistence changes should be discussed in an issue before implementation.

By participating, you agree to follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Development setup

Requirements:

- macOS 14 or newer;
- Xcode Command Line Tools with Swift 6;
- Git.

Clone and validate:

```bash
git clone https://github.com/rjn28/Quartz.git
cd Quartz
./scripts/check.sh
```

Useful targeted commands:

```bash
swift build
swift test
swift run QuartzApp
./scripts/package_app.sh
```

## Making a change

1. Create a focused branch from an up-to-date `main`.
2. Preserve persisted-data compatibility or add an explicit, idempotent migration.
3. Add or update tests whenever behavior changes.
4. Update public documentation for user-visible, setup, configuration, or release changes.
5. Run `./scripts/check.sh` before opening a pull request.

The source layout is documented in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Code expectations

- Keep UI state on the main actor and isolate file/platform work in services.
- Prefer one invariant model over combinations of mutually exclusive booleans.
- Avoid force unwraps, swallowed errors, and destructive data migrations.
- Preserve accessibility labels, keyboard access, reduced-motion behavior, dark/light appearance, and multi-window semantics.
- Do not add dependencies unless their value clearly exceeds their maintenance and supply-chain cost.

## Commits and pull requests

Use concise Conventional Commit-style messages where practical, for example:

```text
fix(persistence): migrate legacy canvas data
feat(export): paginate PDF output
docs: clarify release trust model
```

Stage only intended paths or hunks:

```bash
git add -- path/to/file
git add -p -- path/to/file
git diff --cached
```

Pull requests should explain the problem, the chosen solution, tests performed, data-migration impact, and screenshots for meaningful UI changes. Keep unrelated cleanup out of the same pull request.

## Release work

Do not publish ad hoc-signed artifacts as trusted releases. Maintainers must follow [docs/RELEASING.md](docs/RELEASING.md).
