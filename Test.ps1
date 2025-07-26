$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl

New-Item "$env:APPDATA\Minecraft Server" -ItemType Directory -Force | Out-Null
Set-Content -Path "$env:APPDATA\Minecraft Server\eula.txt" -Value "eula=true"
$ProgressPreference = 'SilentlyContinue'

$filePath = "$env:APPDATA\Minecraft Server\server.jar"
if (-not (Test-Path $filePath)) {
    irm $latestReleaseData.downloads.server.url -OutFile $filePath
}

Set-Location  "$env:APPDATA\Minecraft Server"
& java -jar server.jar nogui
