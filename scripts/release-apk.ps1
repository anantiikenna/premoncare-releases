<#
.SYNOPSIS
  Publishes an APK as a GitHub release on the public sidecar repo.

.EXAMPLE
  .\scripts\release-apk.ps1 -Apk .\app-user-release.apk -Version v1.0.1

  Authenticates with the credential already stored by Git Credential Manager.
  Nothing secret is written to disk or to the repo.
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
    "Release $Version exists — replacing asset '$fileName'"
    $assets = Invoke-Gh "https://api.github.com/repos/$Repo/releases/$($rel.id)/assets"
    foreach ($a in @($assets)) {
        if ($a.name -eq $fileName) {
            Invoke-Gh "https://api.github.com/repos/$Repo/releases/assets/$($a.id)" 'DELETE' | Out-Null
        }
    }
}
else {
    "Creating release $Version"
    $b = @{
        tag_name   = $Version
        name       = $(if ($Title) { $Title } else { "Premoncare Android $Version" })
        body       = $(if ($Notes) { $Notes } else { "Premoncare user APK $Version`n`nSHA-256: ``$sum``" })
        draft      = [bool]$Draft
        prerelease = $false
    } | ConvertTo-Json
    $rel = Invoke-Gh "https://api.github.com/repos/$Repo/releases" 'POST' $b
}

# --- upload asset (streams from disk, up to 2 GB) ---------------------
"Uploading $fileName ..."
$url = "https://uploads.github.com/repos/$Repo/releases/$($rel.id)/assets?name=$([uri]::EscapeDataString($fileName))"
$asset = Invoke-RestMethod -Uri $url -Headers $h -Method Put -InFile $Apk `
    -ContentType 'application/vnd.android.package-archive' -UseBasicParsing

"Uploaded: $($asset.browser_download_url)"
"SHA-256 : $sum"
