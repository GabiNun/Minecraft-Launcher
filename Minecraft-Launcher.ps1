New-Item $env:APPDATA\.minecraft\assets\indexes -ItemType Directory -Force | Out-Null
$ProgressPreference = 'SilentlyContinue'

$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl
$json = irm $latestReleaseData.assetIndex.url

$filePath = "$env:APPDATA\.minecraft\client.jar"
if (-not (Test-Path $filePath)) {
    irm $latestReleaseData.downloads.client.url -OutFile $filePath
}

$indexFilePath = "$env:APPDATA\.minecraft\assets\indexes\$($latestReleaseData.assets).json"
if (-not (Test-Path $indexFilePath)) {
    irm $latestReleaseData.assetIndex.url -OutFile $indexFilePath
}

foreach ($lib in $latestReleaseData.libraries) {
    if ($lib.downloads -and $lib.downloads.artifact) {
        $path = $lib.downloads.artifact.path.ToLower()
        $skip = ($lib.rules -and ($lib.rules | Where-Object { $_.os -and ($_.os.name -match 'linux|macos|arm64') })) -or ($path -match 'linux|macos|arm64')
        if (-not $skip) {
            $file = Join-Path $env:APPDATA ".minecraft\libraries\$($lib.downloads.artifact.path)"
            if (-not (Test-Path (Split-Path $file))) { New-Item -ItemType Directory -Path (Split-Path $file) -Force | Out-Null }
            if (-not (Test-Path $file)) { irm $lib.downloads.artifact.url -OutFile $file; Write-Host "Downloaded $($lib.downloads.artifact.path)" }
        }
    }
}

foreach ($file in $json.objects.PSObject.Properties) {
    $path = $file.Name
    if ($path -like "minecraft/sounds*") { continue }
    if ($path -like "minecraft/lang/*.json" -and -not $path.EndsWith("en_us.json")) { continue }
    $hash = $file.Value.hash
    $subdir = $hash.Substring(0, 2)
    $dest = "$env:APPDATA\.minecraft\assets\objects\$subdir\$hash"
    if (-not (Test-Path $dest)) {
        $dir = Split-Path $dest
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        irm -Uri "https://resources.download.minecraft.net/$subdir/$hash" -OutFile $dest
        Write-Host "Downloaded $path"
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
    "--userType", "legacy",
    "--enable-native-access=ALL-UNNAMED"
)

java -cp $classpathString net.minecraft.client.main.Main $args
