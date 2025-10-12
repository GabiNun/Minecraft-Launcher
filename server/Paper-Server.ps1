irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/ecfe080cecd976ba47f6ba71dca12327f8563f7ce69572168d0777c558f5e977/paper-1.21.10-69.jar -OutFile server
}

java -jar server nogui
