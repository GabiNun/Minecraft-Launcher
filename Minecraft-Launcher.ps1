irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex
$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path "$env:APPDATA\.minecraft")) {
    md $env:APPDATA\.minecraft\assets\indexes | Out-Null
}
Set-Location $env:APPDATA\.minecraft

irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/Microsoft-Login.ps1 | iex

if (-not (Test-Path "client.jar")) {
    Invoke-WebRequest "https://piston-data.mojang.com/v1/objects/ce92fd8d1b2460c41ceda07ae7b3fe863a80d045/client.jar" -OutFile "client.jar"
}

if (-not (Test-Path "assets\indexes\27.json")) {
    Invoke-WebRequest "https://piston-meta.mojang.com/v1/packages/54b287c3d38c95875b76be32659649c092fca091/27.json" -OutFile "assets\indexes\27.json"
}

$json = Invoke-RestMethod "https://piston-meta.mojang.com/v1/packages/5ec1a8f499396c99b4971eb05658fbcf1545e5d0/1.21.9.json"
$assetIndex = Get-Content "assets\indexes\27.json" | ConvertFrom-Json

foreach ($lib in $json.libraries) {
    $path = Join-Path "libraries" $lib.downloads.artifact.path
    $folder = Split-Path $path
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory $folder | Out-Null }
    if (-not (Test-Path $path)) { Invoke-WebRequest $lib.downloads.artifact.url -OutFile $path }
}

foreach ($o in $assetIndex.objects.PSObject.Properties.Value) {
    $path = "$dir\$($o.hash)"
    $dir  = "assets\objects\$($o.hash.Substring(0,2))"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
    if (-not (Test-Path $path)) { Invoke-WebRequest "https://resources.download.minecraft.net/$($o.hash.Substring(0,2))/$($o.hash)" -OutFile $path }
}

$cp = ((gci -R -Fi *.jar | % { $_.FullName }) -join ";") + ";client.jar"

java --enable-native-access=ALL-UNNAMED -cp $cp net.minecraft.client.main.Main --version 1.21.9 -assetIndex 27 --uuid $login.profile.id --username $login.profile.name --accessToken $login.token
