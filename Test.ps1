New-Item $env:APPDATA\.minecraft -ItemType Directory -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'

$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl

$filePath = "$env:APPDATA\.minecraft\client.jar"
if (-not (Test-Path $filePath)) {
    irm $latestReleaseData.downloads.client.url -OutFile $filePath
}

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

$jsonUrl = "https://piston-meta.mojang.com/v1/packages/7eb8873392fc365779dbfea6e2c28fca30a6c6cd/26.json"
$assetsFolder = "assets"

if (-Not (Test-Path $assetsFolder)) {
    New-Item -ItemType Directory -Path $assetsFolder | Out-Null
}

$json = Invoke-RestMethod -Uri $jsonUrl

foreach ($file in $json.objects.PSObject.Properties) {
    $relativePath = $file.Name

    if ($relativePath -like "minecraft/sounds*") {
        continue
    }

    $hash = $file.Value.hash
    $firstTwo = $hash.Substring(0, 2)
    $downloadUrl = "https://resources.download.minecraft.net/$firstTwo/$hash"

    $destinationPath = Join-Path $assetsFolder $relativePath
    $destinationDir = Split-Path $destinationPath

    if (-Not (Test-Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    if (-Not (Test-Path $destinationPath)) {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destinationPath
        Write-Host "Downloaded $relativePath"
    }
}

$classPath = (Get-ChildItem -Path "$env:APPDATA\.minecraft\libraries" -Recurse -Filter *.jar | ForEach-Object { $_.FullName }) + "$env:APPDATA\.minecraft\client.jar"
$classpathString = $classPath -join ';'

$args = @(
    "--version", $latestReleaseData.id,
    "--gameDir", "$env:APPDATA\.minecraft",
    "--assetsDir", "$env:APPDATA\.minecraft\assets",
    "--assetIndex", $latestReleaseData.assets,
    "--uuid", "00000000-0000-0000-0000-000000000000",
    "--username", "Player",
    "--versionType", "release",
    "--accessToken", "0",
    "--userType", "legacy"
)

java -cp $classpathString net.minecraft.client.main.Main $args
