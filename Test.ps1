New-Item $env:APPDATA\.minecraft -ItemType Directory -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'

$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl
$json = irm $latestReleaseData.assetIndex.url

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

if (-Not (Test-Path "$env:APPDATA\.minecraft\assets")) {
    New-Item -ItemType Directory -Path "$env:APPDATA\.minecraft\assets" | Out-Null
}

foreach ($file in $json.objects.PSObject.Properties) {
    if ($file.Name -like "minecraft/sounds*") { continue }

    $hash = $file.Value.hash
    $dest = Join-Path "$env:APPDATA\.minecraft\assets" $file.Name
    if (-Not (Test-Path $dest)) {
        $dir = Split-Path $dest
        if (-Not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Invoke-WebRequest -Uri "https://resources.download.minecraft.net/$($hash.Substring(0,2))/$hash" -OutFile $dest
        Write-Host "Downloaded $($file.Name)"
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
