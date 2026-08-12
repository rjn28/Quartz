# Quartz Roadmap

The roadmap is intentionally short. Priorities can change after user feedback or security findings; completed audit evidence and decision history live in [docs/PROJECT_AUDIT.md](docs/PROJECT_AUDIT.md).

## Now — v1.3.0 release validation

- Validate the real v1.2 preference migration on a backup or disposable macOS account.
- Publish the prepared Developer ID-signed, notarized, checksummed, and attested Apple Silicon `v1.3.0` release.
- Download the public artifact on a clean Apple Silicon Mac and verify Gatekeeper, installation, launch, persistence, and exports.
- Keep Apache-2.0 metadata, the required `main` checks, and immutable release-tag rules enforced.

## Next — data durability and product polish

- Move notes from one `UserDefaults` blob to independently stored, atomic, versioned records in Application Support.
- Normalize drawing coordinates so canvases adapt cleanly to window resizing.
- Add UI automation for launch, multi-window restoration, keyboard commands, VoiceOver, and export flows.
- Add Sparkle only after the first notarized release, with a signed appcast and an explicitly documented rollback/update policy.
- Keep technical documentation in English and maintain the English/French README selector.
- Refresh release screenshots and add a short privacy/data-backup guide.

## Later — optional growth

- Import/export a complete Quartz note package, including canvas data.
- Search and deliberate note-management affordances without turning Quartz into a folder-heavy app.
- Opt-in encrypted sync only if the local-first trust model can be preserved.
- Contributor governance beyond the current single-maintainer model if the community grows.

## Explicit non-goals for now

- Accounts, analytics, advertising, or required network access.
- Mac App Store distribution; the current release strategy remains direct Developer ID distribution with notarization.
- Large third-party UI or persistence frameworks without a demonstrated need.
