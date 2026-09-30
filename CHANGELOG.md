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

## [1.0.0] - 2026-09-27

### Added

- Initial public Android release (user flavor, `com.premoncare.app`).
- APK available for anonymous download from the Premoncare website and from
  this repository's Releases page.

### Checksums

| File | Size | SHA-256 |
| --- | --- | --- |
| `app-user-release.apk` | 190,683,196 bytes | `6208c0c09b1ec835610bbfe96d51e4ba42e32e9fa381a26a9bc32c20bbc7469c` |

[Unreleased]: https://github.com/anantiikenna/premoncare-releases/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/anantiikenna/premoncare-releases/releases/tag/v1.0.0
