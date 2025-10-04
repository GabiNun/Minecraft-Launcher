irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
}
 Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/18ba9d325ceecdf5028fd74bf6c8daa103426308b435bb44de7dadba27b5119b/paper-1.21.9-47.jar -OutFile server.jar
}

java --enable-native-access=ALL-UNNAMED -jar server.jar nogui
