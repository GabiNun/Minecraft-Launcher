irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/23f6560d17e285149c0e486579e3fcc8208dcc171a59c4d021057a9063534732/paper-1.21.10-64.jar -OutFile server
}

java -jar server nogui
