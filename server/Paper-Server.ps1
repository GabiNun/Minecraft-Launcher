irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    ni "$env:APPDATA\Minecraft Server" -I D | Out-Null
    Set-Location "$env:APPDATA\Minecraft Server"
}

if (-not (Test-Path eula.txt)) {
    Set-Content eula.txt eula=true
}

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/8de7c52c3b02403503d16fac58003f1efef7dd7a0256786843927fa92ee57f1e/paper-1.21.8-60.jar -o server.jar
}

& java -jar server.jar nogui
