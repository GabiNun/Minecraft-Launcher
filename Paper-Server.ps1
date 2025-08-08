New-Item "$env:APPDATA\Minecraft Server" -ItemType Directory -Force | Out-Null
Set-Content "$env:APPDATA\Minecraft Server\eula.txt" eula=true
$ProgressPreference = 'SilentlyContinue'

$latestVersion = (irm "https://api.papermc.io/v2/projects/paper").versions[-1]
$latestBuild = (irm "https://api.papermc.io/v2/projects/paper/versions/$latestVersion").builds[-1]
$downloadName = (irm "https://api.papermc.io/v2/projects/paper/versions/$latestVersion/builds/$latestBuild").downloads.application.name

$filePath = "$env:APPDATA\Minecraft Server\server.jar"
if (-not (Test-Path $filePath)) {
    irm api.papermc.io/v2/projects/paper/versions/$latestVersion/builds/$latestBuild/downloads/$downloadName -OutFile $filePath
}

Set-Location "$env:APPDATA\Minecraft Server"
& java -jar server.jar nogui
