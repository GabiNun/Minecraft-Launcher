ni $env:APPDATA\.minecraft\assets\indexes -ItemType Directory -Force | Out-Null
$loginFile = "$env:APPDATA\.minecraft\login.json"

if (Test-Path $loginFile) {
    $login = Get-Content $loginFile -Raw | ConvertFrom-Json
} else {
    irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/Microsoft-Login.ps1 | iex
    ni $loginFile | Out-Null
    Get-Microsoft-Minecraft-Identity
    $login = Get-Content $loginFile -Raw | ConvertFrom-Json
}

$ProgressPreference = 'SilentlyContinue'
$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl

$indexFilePath = "$env:APPDATA\.minecraft\assets\indexes\$($latestReleaseData.assets).json"
$filePath = "$env:APPDATA\.minecraft\client.jar"

if (-not (Test-Path $filePath)) {
    irm $latestReleaseData.downloads.client.url -OutFile $filePath
}

if (-not (Test-Path $indexFilePath)) {
    irm $latestReleaseData.assetIndex.url -OutFile $indexFilePath
}

foreach ($lib in $latestReleaseData.libraries) {
    if ($lib.downloads -and $lib.downloads.artifact) {
        $skip = ($lib.rules -and ($lib.rules | Where-Object { $_.os -and ($_.os.name -match 'linux|macos|arm64') })) -or ($lib.downloads.artifact.path.ToLower() -match 'linux|macos|arm64')
        if (-not $skip) {
            $file = Join-Path $env:APPDATA ".minecraft\libraries\$($lib.downloads.artifact.path)"
            if (-not (Test-Path (Split-Path $file))) { New-Item -ItemType Directory -Path (Split-Path $file) -Force | Out-Null }
            if (-not (Test-Path $file)) { irm $lib.downloads.artifact.url -OutFile $file }
        }
    }
}

foreach ($file in (irm $latestReleaseData.assetIndex.url).objects.PSObject.Properties) {
    if ($file.Name -like "minecraft/sounds*" -or ($file.Name -like "minecraft/lang/*.json" -and -not $file.Name.EndsWith("en_us.json"))) { continue }
    $hash = $file.Value.hash
    $subdir = $hash.Substring(0, 2)
    $dest = "$env:APPDATA\.minecraft\assets\objects\$subdir\$hash"
    if (-not (Test-Path $dest)) {
        $dir = Split-Path $dest
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        irm -Uri "https://resources.download.minecraft.net/$subdir/$hash" -OutFile $dest
    }
}

$classpathString = "$([string]::Join(';', (gci $env:APPDATA\.minecraft\libraries -r -fi *.jar).FullName));$env:APPDATA\.minecraft\client.jar"

java -cp $classpathString net.minecraft.client.main.Main --enable-native-access=ALL-UNNAMED --version $latestReleaseData.id --gameDir "$env:APPDATA\.minecraft" --assetsDir "$env:APPDATA\.minecraft\assets" --assetIndex $latestReleaseData.assets --uuid $login.profile.id --username $login.profile.name --versionType release --accessToken $login.token --userType msa
