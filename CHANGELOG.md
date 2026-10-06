# Changelog

All notable changes to Premoncare **app releases** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## Rules

- Release tags (`vX.Y.Z`) must match `version:` in `apps/mobile/pubspec.yaml`
  (e.g. `1.2.0+3` → tag `v1.2.0`; `+3` is the Android `versionCode`).
- **Published releases are immutable.** Never re-upload an asset to an existing
  tag. If a released build has a mistake, fix forward: bump the version and
  publish a new release. Old APKs stay downloadable at
  `/releases/tag/vX.Y.Z` for rollback.
- One release can carry multiple platforms: `app-user-release.apk` (Android)
  and, in future, `Premoncare.ipa` (iOS) under the same tag.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Fixed

- Emergency joins (web + mobile) now require verified payment
  (`payment_status='completed'`) — closes the payment bypass where entering
  the room flipped status to `ongoing` before paying.
- Completed consultations can rejoin their meeting room; the mobile ownership
  gate no longer accepts `pending`.
- Doctors ending a call are routed to the doctor dashboard instead of the
  patient review screen (reviews were inserted with the wrong `patient_id`).
- iOS `NSCameraUsageDescription` + `NSMicrophoneUsageDescription` added —
  video calls would have crashed on iOS.
- Web meeting room persists `duration_minutes` on call end (parity with
  mobile).
- Jitsi toolbar trimmed on both platforms: mic, camera, screen share, chat,
  hangup, fullscreen, tileview, settings (removes invite link leakage,
  recording, livestreaming, download).
- Documentation corrected to `PremonCare-{appointmentId}` room naming, pinned
  by tests on both platforms.

### Checksums

| File | Size | SHA-256 |
| --- | --- | --- |
| `app-user-release.apk` | 190,847,040 bytes | `fa6f5fbdb4b506c1ba6b645a4594411f74e7ccf7ac6e0934c2b5eabfc3a2787a` |

## [1.0.0] - 2026-09-27

### Added

- Initial public Android release (user flavor, `com.premoncare.app`).
- APK available for anonymous download from the Premoncare website and from
  this repository's Releases page.

### Checksums

| File | Size | SHA-256 |
| --- | --- | --- |
| `app-user-release.apk` | 190,683,196 bytes | `6208c0c09b1ec835610bbfe96d51e4ba42e32e9fa381a26a9bc32c20bbc7469c` |

[Unreleased]: https://github.com/anantiikenna/premoncare-releases/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/anantiikenna/premoncare-releases/releases/tag/v1.0.1
[1.0.0]: https://github.com/anantiikenna/premoncare-releases/releases/tag/v1.0.0
