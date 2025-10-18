irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 0
    irm fill-data.papermc.io/v1/objects/4bfb3447484e7daaacf595158ab4031058fba47be619869b81b3f5c9e6ca9ac2/paper-1.21.10-82.jar -Out server
}

java -jar server nogui
