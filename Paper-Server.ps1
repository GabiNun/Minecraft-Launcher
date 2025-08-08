New-Item "$env:APPDATA\Minecraft Server" -ItemType Directory -Force | Out-Null
sc "$env:APPDATA\Minecraft Server\eula.txt" eula=true
$ProgressPreference = 'SilentlyContinue'

$filePath = "$env:APPDATA\Minecraft Server\server.jar"
if (-not (Test-Path $filePath)) {
    irm fill-data.papermc.io/v1/objects/e799bb4890668c23bdfcf8bb265d10813f9fadd1db5cddfc531e8e4b6f614347/paper-1.21.8-27.jar -OutFile $filePath
}

Set-Location "$env:APPDATA\Minecraft Server"
& java -jar server.jar nogui
