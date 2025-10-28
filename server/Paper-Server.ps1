irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 0
    irm fill-data.papermc.io/v1/objects/f6d8d80d25a687cc52a02a1d04cb25f167bb3a8a828271a263be2f44ada912cc/paper-1.21.10-91.jar -Out server
}

java -jar server nogui
