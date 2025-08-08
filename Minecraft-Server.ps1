New-Item "$env:APPDATA\Minecraft Server" -ItemType Directory -Force | Out-Null
Set-Content "$env:APPDATA\Minecraft Server\eula.txt" eula=true
$ProgressPreference = 'SilentlyContinue'

$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$filePath = "$env:APPDATA\Minecraft Server\server.jar"
if (!(Test-Path $filePath)) {
  $latestReleaseUrl=($manifest.versions | ? id -eq $manifest.latest.release).url
  irm (irm $latestReleaseUrl).downloads.server.url -o $filePath
}

Set-Location "$env:APPDATA\Minecraft Server"
& java -jar server.jar nogui
