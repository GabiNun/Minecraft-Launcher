irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    ni "$env:APPDATA\Minecraft Server" -I D | Out-Null
    Set-Location "$env:APPDATA\Minecraft Server"
}

if (-not (Test-Path eula.txt)) {
    Set-Content eula.txt eula=true
}

$latestVersion = (irm api.papermc.io/v2/projects/paper).versions[-1]
$latestBuild = (irm api.papermc.io/v2/projects/paper/versions/$latestVersion).builds[-1]
$downloadName = (irm api.papermc.io/v2/projects/paper/versions/$latestVersion/builds/$latestBuild).downloads.application.name

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm api.papermc.io/v2/projects/paper/versions/$latestVersion/builds/$latestBuild/downloads/$downloadName -o server.jar
}


& java -jar server.jar nogui
