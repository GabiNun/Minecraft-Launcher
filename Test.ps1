ni $env:APPDATA\.minecraft\assets\indexes -ItemType Directory -Force | Out-Null

if (Test-Path "$env:APPDATA\.minecraft\login.json") {
    Get-Content "$env:APPDATA\.minecraft\login.json" -Raw | ConvertFrom-Json
} else {
    ni "$env:APPDATA\.minecraft\login.json" | Out-Null
    irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/Microsoft-Login.ps1 | iex
    Get-Microsoft-Minecraft-Identity
    Get-Content "$env:APPDATA\.minecraft\login.json" -Raw | ConvertFrom-Json
}

$ProgressPreference = 'SilentlyContinue'

"$env:APPDATA\.minecraft\client.jar" | ForEach-Object {
    Test-Path $_ -or (irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).downloads.client.url -OutFile $_)
}

"$env:APPDATA\.minecraft\assets\indexes\$((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).assetIndex.url).assets).json" |
ForEach-Object {
    Test-Path $_ -or (irm ((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).assetIndex.url) -OutFile $_)
}

((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url)).libraries) |
ForEach-Object {
    $_.downloads.artifact -and (-not ($_.rules -and ($_.rules | Where-Object { $_.os -and ($_.os.name -match 'linux|macos|arm64') })) -and ($_.downloads.artifact.path.ToLower() -notmatch 'linux|macos|arm64')) |
    ForEach-Object {
        Test-Path (Split-Path (Join-Path $env:APPDATA ".minecraft\libraries\$($_.downloads.artifact.path)")) -or (New-Item -ItemType Directory -Path (Split-Path (Join-Path $env:APPDATA ".minecraft\libraries\$($_.downloads.artifact.path)")) -Force | Out-Null)
        Test-Path (Join-Path $env:APPDATA ".minecraft\libraries\$($_.downloads.artifact.path)") -or (irm $_.downloads.artifact.url -OutFile (Join-Path $env:APPDATA ".minecraft\libraries\$($_.downloads.artifact.path)"); Write-Host "Downloaded $($_.downloads.artifact.path)")
    }
}

((irm ((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).assetIndex.url)).objects).PSObject.Properties) |
Where-Object { $_.Name -notlike "minecraft/sounds*" -and ($_.Name -notlike "minecraft/lang/*.json" -or $_.Name.EndsWith("en_us.json")) } |
ForEach-Object {
    Test-Path (Split-Path "$env:APPDATA\.minecraft\assets\objects\$($_.Value.hash.Substring(0,2))\$($_.Value.hash)") -or (New-Item -ItemType Directory -Path (Split-Path "$env:APPDATA\.minecraft\assets\objects\$($_.Value.hash.Substring(0,2))\$($_.Value.hash)") -Force | Out-Null)
    Test-Path "$env:APPDATA\.minecraft\assets\objects\$($_.Value.hash.Substring(0,2))\$($_.Value.hash)" -or (irm -Uri "https://resources.download.minecraft.net/$($_.Value.hash.Substring(0,2))/$.($_.Value.hash)" -OutFile "$env:APPDATA\.minecraft\assets\objects\$($_.Value.hash.Substring(0,2))\$($_.Value.hash)"; Write-Host "Downloaded $($_.Name)")
}

java -cp "$([string]::Join(';', (gci $env:APPDATA\.minecraft\libraries -r -fi *.jar).FullName));$env:APPDATA\.minecraft\client.jar" net.minecraft.client.main.Main `
"--version" ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release) `
"--gameDir" "$env:APPDATA\.minecraft" `
"--assetsDir" "$env:APPDATA\.minecraft\assets" `
"--assetIndex" ((irm ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').versions | ? id -eq ((irm 'https://launchermeta.mojang.com/mc/game/version_manifest.json').latest.release)).url).assetIndex.url).assets `
"--uuid" ((Get-Content "$env:APPDATA\.minecraft\login.json" -Raw | ConvertFrom-Json).profile.id) `
"--username" ((Get-Content "$env:APPDATA\.minecraft\login.json" -Raw | ConvertFrom-Json).profile.name) `
"--versionType" "release" `
"--accessToken" ((Get-Content "$env:APPDATA\.minecraft\login.json" -Raw | ConvertFrom-Json).token) `
"--userType" "msa"
