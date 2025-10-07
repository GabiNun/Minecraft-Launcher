irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex

if (-not (Test-Path "$env:APPDATA\Minecraft Server")) {
    New-Item "$env:APPDATA\Minecraft Server\eula.txt" -Force -Value "eula=true" | Out-Null
}
 Set-Location "$env:APPDATA\Minecraft Server"

if (-not (Test-Path server.jar)) {
    $ProgressPreference = 'SilentlyContinue'
    irm fill-data.papermc.io/v1/objects/3787df5df3c4b0d38d06da66f4b296cd119f10a2067a267119010d06f8dfab0e/paper-1.21.9-58.jar -OutFile server
}

java -jar server nogui
