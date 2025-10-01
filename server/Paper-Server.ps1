irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
    Set-Location "$env:APPDATA\Minecraft Server"
}

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/55785f1c90839e06470dc4c2efc70c909f5e475333b51c5cec32fec14f807443/paper-1.21.9-38.jar -o server.jar
}

java --enable-native-access=ALL-UNNAMED -jar server.jar nogui
