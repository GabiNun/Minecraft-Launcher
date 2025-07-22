$folderPath = Join-Path $env:APPDATA "Minecraft Server"
New-Item -ItemType Directory -Path $folderPath -Force

$jarUrl = "https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
$jarPath = Join-Path $folderPath "server.jar"

if (-Not (Test-Path $jarPath)) {
    Add-Type -AssemblyName System.Net.Http
    $httpClient = [System.Net.Http.HttpClient]::new()
    $response = $httpClient.GetAsync($jarUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
    $stream = $response.Content.ReadAsStreamAsync().Result
    $fileStream = [System.IO.File]::Create($jarPath)
    $stream.CopyTo($fileStream)
    $fileStream.Close()
    $stream.Close()
    $httpClient.Dispose()
}

$eulaPath = Join-Path $folderPath "eula.txt"
Set-Content -Path $eulaPath -Value "eula=true"

Set-Location $folderPath
& java -Xmx8192M -jar "server.jar" nogui
