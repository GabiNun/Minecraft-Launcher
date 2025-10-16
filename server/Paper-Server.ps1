irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/1e92a8f0b1b0c393b3f3a7aa7b73f4940f18c0cea8730152217c6bcf409abe04/paper-1.21.10-76.jar -OutFile server
}

java -jar server nogui
