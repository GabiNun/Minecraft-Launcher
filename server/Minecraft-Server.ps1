irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Value eula=true
    Set-Location "$env:APPDATA\Minecraft Server"
}

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm piston-data.mojang.com/v1/objects/11e54c2081420a4d49db3007e66c80a22579ff2a/server.jar -o server.jar
}

java --enable-native-access=ALL-UNNAMED -jar server.jar nogui
