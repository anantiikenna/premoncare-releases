# premoncare-releases

Public, binary-only sidecar repo for **Premoncare** Android APK downloads.

The main client repo (`Premoncare1`) stays private. This repo exists only so
anonymous website visitors can download the APK from GitHub's CDN.

## Download

https://github.com/anantiikenna/premoncare-releases/releases/latest

## Publish a new APK

From the folder containing the APK:

```powershell
.\scripts\release-apk.ps1 -Apk .\app-user-release.apk -Version v1.0.1
```

The script creates/updates the GitHub release and uploads the APK as the
release asset. It authenticates with the credentials already stored by
Git Credential Manager — no tokens are kept in this repo.
