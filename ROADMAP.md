# Quartz Roadmap

The roadmap is intentionally short. Priorities can change after user feedback or security findings; completed audit evidence and decision history live in [docs/PROJECT_AUDIT.md](docs/PROJECT_AUDIT.md).

## Now — release readiness

- Review and merge the modernization pull request with green CI and CodeQL checks.
- Decide whether Quartz becomes OSI open source or keeps a non-commercial source-available license.
- Configure Apple Developer ID credentials and GitHub's protected `release` environment.
- Publish a signed, notarized, checksummed, and attested `v1.3.0` universal release.
- Protect `main` and release tags after the first successful checks expose stable status names.

## Next — data durability and product polish

- Move notes from one `UserDefaults` blob to independently stored, atomic, versioned records in Application Support.
- Normalize drawing coordinates so canvases adapt cleanly to window resizing.
- Add UI automation for launch, multi-window restoration, keyboard commands, VoiceOver, and export flows.
- Add localization infrastructure and decide whether project documentation should be bilingual.
- Refresh release screenshots and add a short privacy/data-backup guide.

## Later — optional growth

- Import/export a complete Quartz note package, including canvas data.
- Search and deliberate note-management affordances without turning Quartz into a folder-heavy app.
- Opt-in encrypted sync only if the local-first trust model can be preserved.
- Contributor governance beyond the current single-maintainer model if the community grows.

## Explicit non-goals for now

- Accounts, analytics, advertising, or required network access.
- App Store distribution while the current license prohibits it.
- Large third-party UI or persistence frameworks without a demonstrated need.
