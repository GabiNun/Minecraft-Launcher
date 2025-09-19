irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    ni "$env:APPDATA\Minecraft Server" -I D | Out-Null
}

Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path eula.txt)) {
    Set-Content eula.txt eula=true
}

$ProgressPreference = 'SilentlyContinue'

$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$filePath = "$env:APPDATA\Minecraft Server\server.jar"
if (!(Test-Path $filePath)) {
  $latestReleaseUrl=($manifest.versions | ? id -eq $manifest.latest.release).url
  irm (irm $latestReleaseUrl).downloads.server.url -o $filePath
}

Set-Location "$env:APPDATA\Minecraft Server"
& java -jar server.jar nogui
