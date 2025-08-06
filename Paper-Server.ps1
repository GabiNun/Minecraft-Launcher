New-Item "$env:APPDATA\Minecraft Server" -ItemType Directory -Force | Out-Null
Set-Content "$env:APPDATA\Minecraft Server\eula.txt" eula=true
$ProgressPreference = 'SilentlyContinue'

$filePath = "$env:APPDATA\Minecraft Server\server.jar"
if (-not (Test-Path $filePath)) {
    irm fill-data.papermc.io/v1/objects/fb73c7e310215016955617ab957022d9e1d47aeba206df3a98c5ecb43756527c/paper-1.21.8-25.jar -OutFile $filePath
}

Set-Location "$env:APPDATA\Minecraft Server"
& java -jar server.jar nogui
