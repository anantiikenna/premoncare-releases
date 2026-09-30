<#
.SYNOPSIS
  Publishes an APK as a GitHub release on the public sidecar repo.

.DESCRIPTION
  Creates (or updates the release), then uploads the APK as the release asset
  with curl. Authenticates with the credential already stored by Git
  Credential Manager - no tokens are stored on disk or in the repo.

  PUBLISHED releases are immutable: if the tag already exists and is not a
  draft, this script refuses to replace its assets. Publish the next version
  instead (bump pubspec version, use a new -Version). Draft releases may be
  re-run freely to fix an upload before announcing the release.

  A full upload streams straight from disk, shows progress and retries on
  network errors. Router DNS failures are worked around by resolving
  uploads.github.com through 8.8.8.8 and pinning the IP for curl.

.EXAMPLE
  .\scripts\release-apk.ps1 -Apk .\app-user-release.apk -Version v1.0.1
#>
[CmdletBinding()]
param(
    [string]$Apk = ".\app-user-release.apk",
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$Repo = "anantiikenna/premoncare-releases",
    [string]$Title = "",
    [string]$Notes = "",
    [switch]$Draft
)

$ErrorActionPreference = 'Stop'

if (-not $Version.StartsWith('v')) { $Version = "v$Version" }
$Apk = (Resolve-Path -LiteralPath $Apk).Path
$fileName = Split-Path $Apk -Leaf
$fileSize = (Get-Item -LiteralPath $Apk).Length
$sum = (Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash.ToLower()
"APK      : $fileName ($([math]::Round($fileSize / 1MB, 1)) MB)"
"Version  : $Version"
"SHA-256  : $sum"

# --- credential -------------------------------------------------------
$creds = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
$line = $creds | Where-Object { $_ -like 'password=*' }
if (-not $line) { throw 'No GitHub credentials found. Run any git push once to store them.' }
$token = $line.Substring(9)
$h = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json'; 'X-GitHub-Api-Version' = '2022-11-28' }

# --- DNS helper (local resolver is unreliable for githubusercontent) ---
function Get-ResolvedIp([string]$Host_) {
    try {
        $a = [System.Net.Dns]::GetHostAddresses($Host_) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
        if ($a) { return $a.IPAddressToString }
    } catch { }
    try {
        $a = (Resolve-DnsName $Host_ -Type A -Server 8.8.8.8 -ErrorAction Stop) | Where-Object { $_.IPAddress } | Select-Object -First 1
        if ($a) { return $a.IPAddress }
    } catch { }
    throw "Cannot resolve $Host_"
}

function Invoke-Gh([string]$Uri, [string]$Method = 'GET', $Body = $null) {
    $p = @{ Uri = $Uri; Headers = $h; Method = $Method; UseBasicParsing = $true }
    if ($Body) { $p.Body = $Body; $p.ContentType = 'application/json' }
    try { Invoke-RestMethod @p }
    catch {
        $r = $_.Exception.Response
        if ($r) {
            $sr = New-Object System.IO.StreamReader($r.GetResponseStream())
            throw "GitHub API $Method $Uri -> $([int]$r.StatusCode): $($sr.ReadToEnd())"
        }
        throw
    }
}

# --- release ----------------------------------------------------------
$rel = $null
try { $rel = Invoke-Gh "https://api.github.com/repos/$Repo/releases/tags/$Version" } catch { }

if ($rel) {
    if (-not $rel.draft) {
        throw ("Release $Version already exists and is PUBLISHED - releases are immutable, refusing to replace its assets.`n" +
               "If the released build has a mistake, fix forward: bump the version (e.g. -Version v1.0.1) and publish a new release.`n" +
               "Old builds stay available at https://github.com/$Repo/releases/tag/$Version for rollback.`n" +
               "To replace a *draft* release, delete the draft at https://github.com/$Repo/releases first.")
    }
    "Draft release $Version exists - replacing asset '$fileName'"
    $assets = Invoke-Gh "https://api.github.com/repos/$Repo/releases/$($rel.id)/assets"
    foreach ($a in @($assets)) {
        if ($a.name -eq $fileName) {
            Invoke-Gh "https://api.github.com/repos/$Repo/releases/assets/$($a.id)" 'DELETE' | Out-Null
            "  removed old asset $($a.id)"
        }
    }
}
else {
    "Creating release $Version"
    $b = @{
        tag_name   = $Version
        name       = $(if ($Title) { $Title } else { "Premoncare Android $Version" })
        body       = $(if ($Notes) { $Notes } else { "Premoncare user APK $Version`n`nSHA-256: $sum" })
        draft      = [bool]$Draft
        prerelease = $false
    } | ConvertTo-Json
    $rel = Invoke-Gh "https://api.github.com/repos/$Repo/releases" 'POST' $b
    if (-not $rel) { throw 'Release creation failed.' }
}

# --- upload -----------------------------------------------------------
# curl's config parser eats backslashes inside quotes, so paths use / here.
$apkCfg = $Apk -replace '\\', '/'
$target = "uploads.github.com/repos/$Repo/releases/$($rel.id)/assets?name=$([uri]::EscapeDataString($fileName))"
$ip = Get-ResolvedIp 'uploads.github.com'
"uploads.github.com -> $ip"

$cfgLines = @(
    ('url = "https://' + $target + '"')
    'request = "PUT"'
    ('header = "Authorization: Bearer ' + $token + '"')
    'header = "Accept: application/vnd.github+json"'
    'header = "Content-Type: application/vnd.android.package-archive"'
    ('data-binary = "@' + $apkCfg + '"')
)
$cfg = Join-Path $env:TEMP 'curl-apk-release.cfg'
[System.IO.File]::WriteAllText($cfg, ($cfgLines -join [Environment]::NewLine))

"Uploading $fileName ..."
try {
    & curl.exe --resolve "uploads.github.com:443:$ip" --progress-bar `
        --retry 3 --retry-all-errors --retry-delay 5 `
        --connect-timeout 30 --speed-limit 4096 --speed-time 60 --max-time 3000 `
        -K $cfg
    if ($LASTEXITCODE -ne 0) { throw "curl failed with exit code $LASTEXITCODE" }
}
finally {
    Remove-Item -LiteralPath $cfg -Force -ErrorAction SilentlyContinue
}

# --- verify -----------------------------------------------------------
$asset = $null
for ($i = 0; $i -lt 10; $i++) {
    $asset = (Invoke-Gh "https://api.github.com/repos/$Repo/releases/$($rel.id)/assets") |
        Where-Object { $_.name -eq $fileName } | Select-Object -First 1
    if ($asset -and $asset.state -eq 'uploaded') { break }
    Start-Sleep -Seconds 2
}
if (-not $asset) { throw 'Asset not found after upload.' }
if ($asset.size -ne $fileSize) { throw "Size mismatch: uploaded $($asset.size), expected $fileSize" }

"Uploaded: $($asset.browser_download_url)"
"Size     : $($asset.size) bytes (verified)"
"SHA-256  : $sum"
