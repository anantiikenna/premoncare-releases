# premoncare-releases

Public, binary-only sidecar repo for **Premoncare** Android APK downloads.

The main client repo (`Premoncare1`) stays private. This repo exists only so
anonymous website visitors can download the APK from GitHub's CDN.

## Download

Latest: https://github.com/anantiikenna/premoncare-releases/releases/latest

All versions (rollback): https://github.com/anantiikenna/premoncare-releases/releases

Verify a download against the SHA-256 published in the release notes and in
[CHANGELOG.md](CHANGELOG.md).

## Versioning & releases

- One **tag + GitHub Release per version** (`v1.0.0`, `v1.0.1`, …) — never a
  branch. Tags must match `version:` in the main repo's
  `apps/mobile/pubspec.yaml`.
- **Published releases are immutable.** The publish script refuses to replace
  assets on an existing published release. Mistaken build? Bump the version
  and publish a new release; old builds stay downloadable forever, so rollback
  = point users at `/releases/tag/vX.Y.Z`.
- Document every release in [CHANGELOG.md](CHANGELOG.md) (Keep a Changelog
  format) and paste the entry + checksum into the GitHub release notes.
- Future iOS builds (`.ipa`) go on the **same tag** as a second asset.

## Publish a new APK

1. Bump `version:` in `apps/mobile/pubspec.yaml` (e.g. `1.1.0+2`).
2. Build: `flutter build apk --flavor user --release`
3. From the folder containing the APK:

```powershell
.\scripts\release-apk.ps1 -Apk .\app-user-release.apk -Version v1.1.0 -Notes "changelog entry..."
```

4. Update `APK_META` (version / size / SHA-256) in the main repo's
   `apps/web/src/lib/android-download.ts` — that's where the download-button
   metadata lives (the website `.env` only holds the stable
   `/releases/latest/download/` URL).
5. Main repo: redeploy the site with cache cleared so the new `NEXT_PUBLIC_*`
   build inlines pick up the change.

The script creates the GitHub release and uploads the APK as the release
asset. It authenticates with the credentials already stored by Git
Credential Manager — no tokens are kept in this repo. Re-running with an
existing **published** version throws; with a draft it replaces the asset
(fix uploads before announcing).
