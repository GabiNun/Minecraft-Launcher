$folderPath = Join-Path $env:APPDATA "Minecraft Server"
New-Item -ItemType Directory -Path $folderPath -Force

$jarUrl = "https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
$jarPath = Join-Path $folderPath "server.jar"

if (-Not (Test-Path $jarPath)) {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($jarUrl, $jarPath)
}

$eulaPath = Join-Path $folderPath "eula.txt"
Set-Content -Path $eulaPath -Value "eula=true"

Set-Location $folderPath
& java -Xmx8192M -jar "server.jar" nogui
