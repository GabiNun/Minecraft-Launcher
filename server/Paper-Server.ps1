irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    ni "$env:APPDATA\Minecraft Server" -I D | Out-Null
    Set-Location "$env:APPDATA\Minecraft Server"
    Set-Content eula.txt eula=true
}

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/9a51088d04ecf56da32834335271122011e3c58d3bf24d8007f476071e390602/paper-1.21.9-37.jar -o server.jar
}

java --enable-native-access=ALL-UNNAMED -jar server.jar nogui
