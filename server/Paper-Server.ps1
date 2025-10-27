irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 0
    irm fill-data.papermc.io/v1/objects/764ea594261bfe4902c775994f122ba26a1d25b9cc61705867637b751950cd56/paper-1.21.10-89.jar -Out server
}

java -jar server nogui
