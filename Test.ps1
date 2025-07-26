New-Item $env:APPDATA\.minecraft -ItemType Directory -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'

$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl

irm $latestReleaseData.downloads.client.url -OutFile $env:APPDATA\.minecraft\client.jar

foreach ($lib in $latestReleaseData.libraries) {
    if ($lib.downloads?.artifact) {
        $path = $lib.downloads.artifact.path.ToLower()
        $skip = $lib.rules -and ($lib.rules | Where-Object { $_.os -and ($_.os.name -match 'linux|macos|arm64') }) -or ($path -match 'linux|macos|arm64')
        if (-not $skip) {
            $file = Join-Path $env:APPDATA ".minecraft\libraries\$($lib.downloads.artifact.path)"
            if (-not (Test-Path (Split-Path $file))) { New-Item -ItemType Directory -Path (Split-Path $file) -Force | Out-Null }
            if (-not (Test-Path $file)) { irm $lib.downloads.artifact.url -OutFile $file; Write-Host "Downloaded $($lib.downloads.artifact.path)" }
        }
    }
}
