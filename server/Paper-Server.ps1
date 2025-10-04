irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
}
 Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/4cac1132df2c0998cdcd150a7b201acfea55ebe60b3325d388597934aa2bb1c7/paper-1.21.9-49.jar -OutFile server.jar
}

java --enable-native-access=ALL-UNNAMED -jar server.jar nogui
