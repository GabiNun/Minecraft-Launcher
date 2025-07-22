$ProgressPreference = 'SilentlyContinue'

New-Item -ItemType Directory "$env:APPDATA\Minecraft Server" -Force | Out-Null
Set-Content -Path "$env:APPDATA\Minecraft Server\eula.txt" -Value "eula=true"

if (-Not (Test-Path "$env:APPDATA\Minecraft Server\server.jar")) {
    $url = if ((Read-Host "Choose server type (default/paper)").ToLower() -eq "paper") {
        "https://fill-data.papermc.io/v1/objects/9457d1279efcc2094e818cacb2f17670d9479e5f6b4ea2517eb93a6a3face51f/paper-1.21.8-11.jar"
    } else {
        "https://piston-data.mojang.com/v1/objects/6bce4ef400e4efaa63a13d5e6f6b500be969ef81/server.jar"
    }
    Invoke-WebRequest $url -OutFile "$env:APPDATA\Minecraft Server\server.jar"
}

Set-Location "$env:APPDATA\Minecraft Server"
& java -Xmx8192M -jar server.jar nogui
