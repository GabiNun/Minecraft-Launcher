New-Item $env:APPDATA\.minecraft -ItemType Directory -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'

$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl

irm $latestReleaseData.downloads.client.url -OutFile $env:APPDATA\.minecraft\client.jar

foreach ($lib in $latestReleaseData.libraries) {
    if ($lib.downloads -and $lib.downloads.artifact) {
        $filePath = Join-Path $env:APPDATA ".minecraft\libraries\$($lib.downloads.artifact.path)"
        if (-not (Test-Path (Split-Path $filePath))) {
            New-Item -ItemType Directory -Path (Split-Path $filePath) -Force | Out-Null
        }
        if (-not (Test-Path $filePath)) {
            irm $lib.downloads.artifact.url -OutFile $filePath
            Write-Host "Downloaded $($lib.downloads.artifact.path)"
        }
    }
}
