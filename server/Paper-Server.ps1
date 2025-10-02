irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
}
 Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/3f67ba5e8f29f62a11791406c11a8d23800cb60cfb06cab93f942c9ad94cce5e/paper-1.21.9-45.jar -OutFile server.jar
}

java --enable-native-access=ALL-UNNAMED -jar server.jar nogui
