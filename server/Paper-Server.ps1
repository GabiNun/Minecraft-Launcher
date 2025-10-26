irm github.com/GabiNun/Minecraft-Launcher/raw/main/server/Get-Java.ps1 | iex
New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 0
    irm fill-data.papermc.io/v1/objects/7434a3ab634ed79541c37b2ab1a37b0356b8949d6c83f8de4ec9e5794b3e7ad8/paper-1.21.10-88.jar -Out server
}

java -jar server nogui
