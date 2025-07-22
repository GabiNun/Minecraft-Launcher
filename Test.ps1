$mcPath = "$env:APPDATA\minecraft"
$manifest = Invoke-RestMethod -Uri "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
$latestReleaseId = $manifest.latest.release
$latestReleaseUrl = ($manifest.versions | Where-Object { $_.id -eq $latestReleaseId }).url
$versionData = Invoke-RestMethod -Uri $latestReleaseUrl

$versionDir = Join-Path $mcPath "versions\$latestReleaseId"
if (-not (Test-Path $versionDir)) { New-Item -ItemType Directory -Path $versionDir -Force }
$clientJarPath = Join-Path $versionDir "$latestReleaseId.jar"
Invoke-WebRequest -Uri $versionData.downloads.client.url -OutFile $clientJarPath

$assetIndexUrl = $versionData.assetIndex.url
$assetIndexData = Invoke-RestMethod -Uri $assetIndexUrl

foreach ($lib in $versionData.libraries) {
    if ($lib.downloads -and $lib.downloads.artifact) {
        $url = $lib.downloads.artifact.url

        $relativePath = $url.Split('/')[-4..-1] -join '/'
        $libraryPath = Join-Path $mcPath "libraries\$relativePath"
        $libraryDir = Split-Path $libraryPath

        if (-not (Test-Path $libraryDir)) { New-Item -ItemType Directory -Path $libraryDir -Force }
        if (-not (Test-Path $libraryPath)) {
            Invoke-WebRequest -Uri $url -OutFile $libraryPath
        }
    }
}

foreach ($asset in $assetIndexData.objects.GetEnumerator()) {
    $assetName = $asset.Key
    $hash = $asset.Value.hash

    if ($assetName -like "sounds/*") {
        continue
    }

    $subFolder = $hash.Substring(0,2)
    $assetPath = Join-Path $mcPath "assets\objects\$subFolder\$hash"

    if (-not (Test-Path $assetPath)) {
        $assetUrl = "https://resources.download.minecraft.net/$subFolder/$hash"
        $assetDir = Split-Path $assetPath
        if (-not (Test-Path $assetDir)) { New-Item -ItemType Directory -Path $assetDir -Force }
        Invoke-WebRequest -Uri $assetUrl -OutFile $assetPath
    }
}
