irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 0
    irm piston-data.mojang.com/v1/objects/95495a7f485eedd84ce928cef5e223b757d2f764/server.jar -OutFile server
}

java -jar server nogui
