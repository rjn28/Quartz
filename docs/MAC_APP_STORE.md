# Mac App Store Distribution

Quartz can be distributed as a free, Apple Silicon-only Mac App Store app under the existing Apple Developer Program membership. The direct GitHub release remains a separate supported channel.

## Distribution model

| Channel | Signature and delivery | Updates | Sandbox |
| --- | --- | --- | --- |
| GitHub | Developer ID, notarized and stapled DMG | Sparkle may be added later | Not required |
| Mac App Store | Apple distribution signing, App Store Connect, and App Review | Mac App Store | Required |

The Store build must not include Sparkle or another self-update mechanism. Shared application code should remain identical wherever possible; distribution-specific signing, entitlements, packaging, and update behavior must stay explicit.

## Current readiness audit

Ready:

- active Apple Developer Program membership and team;
- stable bundle identifier `com.rjn28.Quartz` in the direct build;
- native SwiftUI app with no account, analytics, advertising, network dependency, or third-party runtime dependency;
- Apple Silicon-only product decision and macOS 14 minimum;
- tested application icon, version source, automated tests, and public release process;
- Apache-2.0 licensing permits App Store distribution.

Required before the first upload:

1. **Add an Xcode macOS application target.** The package-only Xcode archive currently installs `QuartzApp` under `Products/usr/local/bin`; it does not create an App Store-ready `.app` archive. Keep `Package.swift` for package builds and tests while adding a small app project/target that reuses the existing sources and resources.
2. **Adopt App Sandbox.** The Store target needs `com.apple.security.app-sandbox = true` and only the capabilities Quartz actually uses.
3. **Make exports user-selected.** The current export action writes directly to the Desktop. Replace it with `NSSavePanel` or SwiftUI `fileExporter`, and enable `com.apple.security.files.user-selected.read-write`. Dragging a temporary export to Finder can remain, subject to sandbox testing.
4. **Protect existing user data.** A sandboxed Store build receives a container separate from the direct build's current preferences. Define and test a full-note export/import or a reviewed migration path before presenting the Store build as an in-place replacement.
5. **Create Apple distribution assets.** Register the explicit App ID `com.rjn28.Quartz`, create the macOS app record, and use Xcode automatic signing or a Mac App Store Connect provisioning profile with an Apple Distribution or Mac App Distribution certificate.
6. **Prepare Store metadata.** Reserve the app name, select Productivity, provide description, keywords, support and privacy-policy URLs, age rating, copyright, review notes, and required 16:10 Mac screenshots.
7. **Declare privacy accurately.** Quartz currently collects no data. Confirm that statement against the exact submitted binary and publish a stable privacy policy URL before submission.
8. **Validate through TestFlight.** Upload a release candidate, test installation, launch, persistence, multiple windows, drawing, TXT/PDF exports, light/dark appearance, offline behavior, and migration/import before App Review.

## Recommended implementation sequence

### 1. Store-compatible application code

- introduce a save-panel export boundary that is shared by both channels;
- add tests for cancellation, TXT/PDF destinations, collisions, and write failures;
- add a complete Quartz note export/import format for moving data safely between channels;
- keep the current Developer ID DMG pipeline green throughout the work.

### 2. Xcode distribution target

- add a minimal macOS app target that reuses `Sources/Quartz` and the asset catalog;
- set the deployment target to macOS 14 and architectures to `arm64` only;
- make `VERSION` and the CI build number feed both distribution channels;
- add a Store-only entitlements file with App Sandbox and user-selected read/write access;
- verify that the archived product is `Products/Applications/Quartz.app`.

### 3. Apple configuration

- register the explicit App ID and create the macOS app record in App Store Connect;
- let Xcode manage the App Store distribution certificate/profile initially;
- choose the free price and desired storefront availability;
- publish the privacy policy and complete the data-collection questionnaire;
- upload screenshots and accurate English metadata, with French localization optional.

### 4. Validation and submission

- archive and run Xcode's **Validate App** action;
- upload to App Store Connect and wait for processing;
- distribute the build through TestFlight for macOS;
- record results in `docs/TEST_TRACKER.md`;
- select the tested build, add it for review, and submit it to App Review;
- keep the GitHub DMG available for users who prefer direct distribution.

## Release rules

- The first Store submission should use a new version after `1.3.0`; `1.4.0` is the proposed target unless intervening work requires another version.
- Build numbers must remain unique within each submitted version.
- The Store and direct builds may share the bundle identifier only after their data-container and update-channel behavior has been tested explicitly.
- A Store rejection is tracked as a normal release defect; do not weaken the sandbox or hide behavior from App Review to bypass it.

## Definition of ready for first upload

- [ ] Xcode archive contains a signed `Quartz.app`, not a command-line installation.
- [ ] App Sandbox is active with a minimal entitlement set.
- [ ] TXT and PDF exports work through a user-selected destination.
- [ ] Direct-to-Store data migration/import is documented and tested.
- [ ] Developer ID GitHub release checks still pass.
- [ ] Explicit App ID and App Store Connect record exist.
- [ ] Privacy policy, privacy answers, metadata, screenshots, and review notes are complete.
- [ ] Store archive validation passes without warnings that affect users or review.
- [ ] TestFlight acceptance passes on a clean Apple Silicon environment.
