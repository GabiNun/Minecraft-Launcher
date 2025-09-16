irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server" -ItemType Directory -Force | Out-Null
Set-Content "$env:APPDATA\Minecraft Server\eula.txt" eula=true
$ProgressPreference = 'SilentlyContinue'

$latestVersion = (irm api.papermc.io/v2/projects/paper).versions[-1]
$latestBuild = (irm api.papermc.io/v2/projects/paper/versions/$latestVersion).builds[-1]
$downloadName = (irm api.papermc.io/v2/projects/paper/versions/$latestVersion/builds/$latestBuild).downloads.application.name

$filePath = "$env:APPDATA\Minecraft Server\server.jar"
if (-not (Test-Path $filePath)) {
    irm api.papermc.io/v2/projects/paper/versions/$latestVersion/builds/$latestBuild/downloads/$downloadName -o $filePath
}

Set-Location "$env:APPDATA\Minecraft Server"
& java -jar server.jar nogui
