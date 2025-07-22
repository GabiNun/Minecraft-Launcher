$ProgressPreference = 'SilentlyContinue'

New-Item -ItemType Directory -Path "$env:APPDATA\Minecraft Server" -Force
Set-Content -Path "$env:APPDATA\Minecraft Server\eula.txt" -Value "eula=true"

if (-Not (Test-Path "$env:APPDATA\Minecraft Server\server.jar")) {
    Invoke-WebRequest -Uri "https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar" -OutFile "$env:APPDATA\Minecraft Server\server.jar"
}

& java -Xmx8192M -jar "$env:APPDATA\Minecraft Server\server.jar" nogui
