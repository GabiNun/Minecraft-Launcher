irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    ni "$env:APPDATA\Minecraft Server" -I D | Out-Null
    Set-Location "$env:APPDATA\Minecraft Server"
}

if (-not (Test-Path eula.txt)) {
    Set-Content eula.txt eula=true
}

if (-not (Test-Path server.jar)) {
    curl.exe -s -o server.jar piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar
}

& java -jar server.jar nogui
