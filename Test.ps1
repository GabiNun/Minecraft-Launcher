ni $env:APPDATA\.minecraft\assets\indexes -ItemType Directory -Force | Out-Null
$loginFile = "$env:APPDATA\.minecraft\login.json"

if (Test-Path $loginFile) {
    $login = Get-Content $loginFile -Raw | ConvertFrom-Json
} else {
    ni $loginFile | Out-Null
    irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/Microsoft-Login.ps1 | iex
    Get-Microsoft-Minecraft-Identity
    $login = Get-Content $loginFile -Raw | ConvertFrom-Json
}

$ProgressPreference = 'SilentlyContinue'

"$env:APPDATA\.minecraft\client.jar" | ForEach-Object { Test-Path $_ -or (irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).downloads.client.url -OutFile $_) }

"$env:APPDATA\.minecraft\assets\indexes\$((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).assetIndex.url).assets).json" | 
    ForEach-Object { Test-Path $_ -or (irm ((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).assetIndex.url) -OutFile $_) }

((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url)).libraries) | 
    ForEach-Object { 
        $_.downloads.artifact -and (-not ($_.rules -and ($_.rules | Where-Object { $_.os -and ($_.os.name -match 'linux|macos|arm64') })) -and ($_.downloads.artifact.path.ToLower() -notmatch 'linux|macos|arm64')) | 
        ForEach-Object { 
            $filePath = Join-Path $env:APPDATA ".minecraft\libraries\$($_.downloads.artifact.path)"
            Test-Path (Split-Path $filePath) -or (New-Item -ItemType Directory -Path (Split-Path $filePath) -Force | Out-Null)
            Test-Path $filePath -or (irm $_.downloads.artifact.url -OutFile $filePath; Write-Host "Downloaded $($_.downloads.artifact.path)")
        } 
    }

((irm ((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).assetIndex.url)).objects).PSObject.Properties) |
    Where-Object { $_.Name -notlike "minecraft/sounds*" -and ($_.Name -notlike "minecraft/lang/*.json" -or $_.Name.EndsWith("en_us.json")) } |
    ForEach-Object { 
        $dest = "$env:APPDATA\.minecraft\assets\objects\$($_.Value.hash.Substring(0,2))\$($_.Value.hash)"
        Test-Path (Split-Path $dest) -or (New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null)
        Test-Path $dest -or (irm -Uri "https://resources.download.minecraft.net/$($_.Value.hash.Substring(0,2))/$.($_.Value.hash)" -OutFile $dest; Write-Host "Downloaded $($_.Name)")
    }

$classpathString = "$([string]::Join(';', (gci $env:APPDATA\.minecraft\libraries -r -fi *.jar).FullName));$env:APPDATA\.minecraft\client.jar"

$args = @(
    "--version", $latestReleaseData.id,
    "--gameDir", "$env:APPDATA\.minecraft",
    "--assetsDir", "$env:APPDATA\.minecraft\assets",
    "--assetIndex", $latestReleaseData.assets,
    "--uuid", $login.profile.id,
    "--username", $login.profile.name,
    "--versionType", "release",
    "--accessToken", $login.token,
    "--userType", "msa"
)

java -cp $classpathString net.minecraft.client.main.Main $args
