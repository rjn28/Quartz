# Security Policy

## Supported versions

Security fixes target the latest released version and the current `main` branch. Older ad hoc releases are legacy artifacts and may not receive fixes.

| Version | Support |
| --- | --- |
| Latest release | Supported |
| `main` | Supported for coordinated disclosure |
| Older releases | Best effort |

## Report a vulnerability

Use GitHub's private vulnerability reporting for this repository. Do not open a public issue for an undisclosed vulnerability and do not include sensitive user data, credentials, or exploit details in public discussions.

Include:

- affected Quartz version and macOS version;
- impact and realistic attack scenario;
- reproduction steps or a minimal proof of concept;
- suggested remediation, if known;
- whether the issue is already public.

The maintainer aims to acknowledge a report within seven days, confirm severity and next steps within fourteen days, and coordinate disclosure after a fix is available. Timelines may change for a volunteer-maintained project, but good-faith reporters will receive status updates.

## Distribution trust

Starting with the next release pipeline, public artifacts must be Developer ID-signed, hardened-runtime enabled, notarized, stapled, checksummed, and accompanied by GitHub artifact provenance. The automated release job fails closed when any prerequisite is absent.

Releases before `v1.3.0` were ad hoc-signed, not notarized, and should be treated as legacy artifacts. Quartz never asks users to disable Gatekeeper or remove quarantine attributes.

## Scope

Relevant reports include unsafe persistence or migration behavior, arbitrary file access or overwrite, malicious note/export handling, supply-chain compromise, signing/notarization bypass, and accidental disclosure of locally stored note content.
