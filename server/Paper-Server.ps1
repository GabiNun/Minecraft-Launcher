irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 0
    irm fill-data.papermc.io/v1/objects/461bf33493781600a2163b1ee84237b2cac5401d5e1c70801742a617e51df26c/paper-1.21.10-84.jar -Out server
}

java -jar server nogui
