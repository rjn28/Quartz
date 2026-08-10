# Releasing Quartz

Public releases must be reproducible, Apple Silicon-only, Developer ID-signed, notarized, stapled, checksummed, and traceable to a signed GPG tag on `main`. Ad hoc output from local packaging is for testing only.

## Version policy

- `VERSION` is the single source for `CFBundleShortVersionString`.
- New tags use full Semantic Versioning: `vX.Y.Z`.
- The GitHub Release workflow run number plus 1000 becomes the monotonic `CFBundleVersion` in automated releases, keeping new builds above the historical build `1`.
- Historical tags remain unchanged even though `v1.1` and `v1.2` predate this convention.

## Local preflight

```bash
./scripts/check.sh
./scripts/package_app.sh
hdiutil verify "BuildArtifacts/Quartz-$(<VERSION).dmg"
```

The default local artifact is Apple Silicon-only but ad hoc-signed. Inspect it with:

```bash
codesign --display --verbose=4 /path/to/Quartz.app
lipo -archs /path/to/Quartz.app/Contents/MacOS/Quartz
plutil -p /path/to/Quartz.app/Contents/Info.plist
```

## One-time GitHub configuration

Create a protected `release` environment and configure these Actions secrets:

| Secret | Purpose |
| --- | --- |
| `TAG_SIGNING_PUBLIC_KEY` | Armored public GPG key used to verify release tags |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded Developer ID Application `.p12` |
| `P12_PASSWORD` | Password for the `.p12` |
| `KEYCHAIN_PASSWORD` | Ephemeral CI keychain password |
| `DEVELOPER_ID_APPLICATION` | Exact signing identity name |
| `APPLE_ID` | Apple account used by `notarytool` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific Apple password |
| `APPLE_TEAM_ID` | Apple Developer Team ID |

Use environment protection and least-privilege access for maintainers who may publish. Never commit or print these values.

## Release procedure

1. Ensure `main` is green and the changelog's Unreleased section is ready.
2. Update `VERSION` to `X.Y.Z`, move changelog entries into an `X.Y.Z - YYYY-MM-DD` section, and commit.
3. Create and verify a signed annotated GPG tag whose public key is stored in the protected `TAG_SIGNING_PUBLIC_KEY` environment secret:

   ```bash
   git tag -s "v$(<VERSION)" -m "Quartz $(<VERSION)"
   git tag -v "v$(<VERSION)"
   ```

4. Push the tag without force:

   ```bash
   git push origin "v$(<VERSION)"
   ```

5. The `Release` workflow validates the tag/version, imports the certificate into an ephemeral keychain, packages the Apple Silicon app, notarizes and staples the DMG, assesses it with Gatekeeper, creates a checksum and provenance attestation, and publishes the GitHub release.
6. Download the public asset on a clean Mac and verify install, launch, text persistence, canvas migration, TXT/PDF export, architecture, checksum, signature, and stapled ticket.

   ```bash
   shasum -a 256 -c "Quartz-X.Y.Z.dmg.sha256"
   gh attestation verify "Quartz-X.Y.Z.dmg" --repo rjn28/Quartz
   ```

## Failure policy

Do not bypass a failed signature, notarization, tag verification, CI check, or Gatekeeper assessment. Diagnose and rerun from a new commit/tag when appropriate; never move an already published release tag.

If credentials are unavailable, publish source changes without a binary release rather than distributing a build that asks users to weaken macOS security.

## Post-notarization update roadmap

Sparkle is intentionally deferred until the first Developer ID-signed and notarized Quartz release has been validated on a clean Mac. The later integration must use a signed appcast, EdDSA update signatures, HTTPS hosting, rollback documentation, and tests proving that update verification fails closed. Sparkle must not weaken the release workflow or become a substitute for notarization.
