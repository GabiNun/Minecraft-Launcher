$version = "1.21.8"
$versionJson = Join-Path $env:TEMP "$version.json"
$workDir = Join-Path $env:APPDATA ".minecraft"
$librariesDir = Join-Path $workDir "libraries"
$assetsDir = Join-Path $workDir "assets"
$clientJar = Join-Path $workDir "client.jar"

$ProgressPreference = 'SilentlyContinue'

if (!(Test-Path $versionJson)) {
    Write-Host "Downloading version JSON: $version"
    Invoke-WebRequest -Uri "https://piston-meta.mojang.com/v1/packages/24b08e167c6611f7ad895ae1e8b5258f819184aa/1.21.8.json" -OutFile $versionJson
}

New-Item -ItemType Directory -Force -Path $librariesDir, $assetsDir, (Join-Path $assetsDir "indexes"), (Join-Path $assetsDir "objects") | Out-Null

$mc = Get-Content $versionJson | ConvertFrom-Json

if (!(Test-Path $clientJar)) {
    Write-Host "Downloading client.jar..."
    Invoke-WebRequest -Uri $mc.downloads.client.url -OutFile $clientJar
}

foreach ($lib in $mc.libraries) {
    $artifact = $lib.downloads.artifact
    if ($null -ne $artifact) {
        $libPath = Join-Path $librariesDir $artifact.path
        $libDir = Split-Path $libPath -Parent
        New-Item -ItemType Directory -Path $libDir -Force | Out-Null
        if (!(Test-Path $libPath)) {
            Write-Host "Downloading library: $($artifact.path)"
            Invoke-WebRequest -Uri $artifact.url -OutFile $libPath
        }
    }
}

$assetIndex = $mc.assetIndex.id
$assetIndexUrl = $mc.assetIndex.url
$assetIndexFile = Join-Path (Join-Path $assetsDir "indexes") "$assetIndex.json"

if (!(Test-Path $assetIndexFile)) {
    Write-Host "Downloading asset index..."
    Invoke-WebRequest -Uri $assetIndexUrl -OutFile $assetIndexFile
}

$assetData = Get-Content $assetIndexFile | ConvertFrom-Json

$needAssets = $false
foreach ($asset in $assetData.objects.PSObject.Properties) {
    if ($asset.Name -like "minecraft/sounds/*") { continue }
    if ($asset.Name -like "minecraft/lang/*.json" -and $asset.Name -ne "minecraft/lang/en_us.json") { continue }
    $hash = $asset.Value.hash
    $dest = Join-Path $assetsDir "objects\$($hash.Substring(0,2))\$hash"
    if (!(Test-Path $dest)) {
        $needAssets = $true
        break
    }
}

if ($needAssets) {
    Write-Host "Parsing asset index and downloading assets (skipping sounds and non-en_us languages)."
    foreach ($asset in $assetData.objects.PSObject.Properties) {
        if ($asset.Name -like "minecraft/sounds/*") { continue }
        if ($asset.Name -like "minecraft/lang/*.json" -and $asset.Name -ne "minecraft/lang/en_us.json") { continue }
        $hash = $asset.Value.hash
        $sub = $hash.Substring(0,2)
        $dest = Join-Path $assetsDir "objects\$sub\$hash"
        if (!(Test-Path $dest)) {
            $url = "https://resources.download.minecraft.net/$sub/$hash"
            $destDir = Split-Path $dest -Parent
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            try {
                Invoke-WebRequest -Uri $url -OutFile $dest -ErrorAction Stop
                Write-Host "Downloaded asset: $($asset.Name)"
            } catch {
                Write-Warning "Failed to download asset: $($asset.Name) ($url)"
            }
        }
    }
}

$libJars = Get-ChildItem -Path $librariesDir -Recurse -Filter *.jar | ForEach-Object { $_.FullName }
$classpath = ($libJars + $clientJar) -join ";"

$username = "Player"
$uuid = "00000000-0000-0000-0000-000000000000"
$accessToken = "offline"

$jvmArgs = @(
    "--enable-native-access=ALL-UNNAMED"
    "-cp", $classpath
)

$gameArgs = @(
    "--username", $username,
    "--version", $version,
    "--gameDir", $workDir,
    "--assetsDir", $assetsDir,
    "--assetIndex", $assetIndex,
    "--uuid", $uuid,
    "--accessToken", $accessToken,
    "--userType", "legacy",
    "--versionType", "release"
)

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Output "Java is not installed. Please install Java 24 Than ReRun"
    exit /b
}

& java @jvmArgs $mc.mainClass @gameArgs
