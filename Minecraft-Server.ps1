$jarUrl = "https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
$folderPath = Join-Path $env:APPDATA "Minecraft Server"
$jarPath = Join-Path $folderPath "server.jar"
$eulaPath = Join-Path $folderPath "eula.txt"

New-Item -ItemType Directory -Path $folderPath -Force
Invoke-WebRequest -Uri $jarUrl -OutFile $jarPath
Set-Content -Path $eulaPath -Value "eula=true"
Set-Location $folderPath
& java -Xmx8192M -jar server.jar nogui
