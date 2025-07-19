# --- User Configurable ---
$version = "1.21.8"
$versionJson = "$env:TEMP\$version.json"
$workDir = "$env:APPDATA\.minecraft"
$librariesDir = "$workDir\libraries"
$assetsDir = "$workDir\assets"

$ProgressPreference = 'SilentlyContinue'

# --- Download version JSON if missing ---
if (!(Test-Path $versionJson)) {
    Write-Host "Downloading version JSON: $version"
    Invoke-WebRequest -Uri "https://piston-meta.mojang.com/v1/packages/24b08e167c6611f7ad895ae1e8b5258f819184aa/1.21.8.json" -OutFile $versionJson
}

# --- Prepare Directories ---
New-Item -ItemType Directory -Force -Path $librariesDir, $assetsDir | Out-Null
New-Item -ItemType Directory -Force -Path "$assetsDir\indexes", "$assetsDir\objects" | Out-Null

# --- Read Version JSON ---
$mc = Get-Content $versionJson | ConvertFrom-Json

# --- Download client.jar ---
$clientJar = "$workDir\client.jar"
If (!(Test-Path $clientJar)) {
    Write-Host "Downloading client.jar..."
    Invoke-WebRequest -Uri $mc.downloads.client.url -OutFile $clientJar
}

# --- Download libraries ---
foreach ($lib in $mc.libraries) {
    $artifact = $lib.downloads.artifact
    if ($null -ne $artifact) {
        $libPath = Join-Path $librariesDir $artifact.path
        $libDir = Split-Path $libPath -Parent
        if (!(Test-Path $libDir)) { New-Item -ItemType Directory -Path $libDir -Force | Out-Null }
        if (!(Test-Path $libPath)) {
            Write-Host "Downloading library: $($artifact.path)"
            Invoke-WebRequest -Uri $artifact.url -OutFile $libPath
        }
    }
}

# --- Download Asset Index ---
$assetIndex = $mc.assetIndex.id
$assetIndexUrl = $mc.assetIndex.url
$assetIndexFile = "$assetsDir\indexes\$assetIndex.json"
if (!(Test-Path $assetIndexFile)) {
    Write-Host "Downloading asset index..."
    Invoke-WebRequest -Uri $assetIndexUrl -OutFile $assetIndexFile
}

# --- Only print asset download message if missing assets ---
$assetData = Get-Content $assetIndexFile | ConvertFrom-Json

# Pre-check for missing assets (skipping sounds and non-en_us languages)
$needAssets = $false
foreach ($asset in $assetData.objects.PSObject.Properties) {
    if ($asset.Name -like "minecraft/sounds/*") { continue }
    if ($asset.Name -like "minecraft/lang/*.json" -and $asset.Name -ne "minecraft/lang/en_us.json") { continue }
    $hash = $asset.Value.hash
    $sub = $hash.Substring(0,2)
    $dest = "$assetsDir\objects\$sub\$hash"
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
        $dest = "$assetsDir\objects\$sub\$hash"
        if (!(Test-Path $dest)) {
            $url = "https://resources.download.minecraft.net/$sub/$hash"
            $destDir = Split-Path $dest -Parent
            if (!(Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory | Out-Null }
            try {
                Invoke-WebRequest -Uri $url -OutFile $dest -ErrorAction Stop
                Write-Host "Downloaded asset: $($asset.Name)"
            } catch {
                Write-Warning "Failed to download asset: $($asset.Name) ($url)"
            }
        }
    }
}

# --- Build classpath ---
$libJars = Get-ChildItem -Path $librariesDir -Recurse -Filter *.jar | ForEach-Object { $_.FullName }
$classpath = ($libJars + $clientJar) -join ";"

# --- Offline arguments ---
$username = "Player"
$uuid = "00000000-0000-0000-0000-000000000000"
$accessToken = "offline"

$jvmArgs = @(
    "--enable-native-access=ALL-UNNAMED"
    "-cp", "$classpath"
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
    Write-Output "Java is not installed. Please install java 24"
}

Write-Host "Launching Minecraft..."
& java @jvmArgs $mc.mainClass @gameArgs
