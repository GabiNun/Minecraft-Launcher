irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex
$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path $env:APPDATA\.minecraft)) {
    New-Item -ItemType Directory $env:APPDATA\.minecraft\assets\indexes | Out-Null
}
Set-Location $env:APPDATA\.minecraft

irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/Microsoft-Login.ps1 | iex

if (-not (Test-Path client.jar)) {
    Invoke-WebRequest "https://piston-data.mojang.com/v1/objects/d3bdf582a7fa723ce199f3665588dcfe6bf9aca8/client.jar" -OutFile "client.jar"
}

if (-not (Test-Path assets\indexes\27.json)) {
    Invoke-WebRequest "https://piston-meta.mojang.com/v1/packages/0eff1bc3fcbc8d1e6e29769296b6efd1688a28bf/27.json" -OutFile "assets\indexes\27.json"
}

$json = Invoke-RestMethod "https://piston-meta.mojang.com/v1/packages/3560c7ad91a0433df0762a36fa2ceffcf0c5cca0/1.21.10.json"
$assetIndex = Get-Content "assets\indexes\27.json" | ConvertFrom-Json

foreach ($lib in $json.libraries) {
    $path = Join-Path "libraries" $lib.downloads.artifact.path
    $folder = Split-Path $path
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory $folder | Out-Null }
    if (-not (Test-Path $path)) { Invoke-WebRequest $lib.downloads.artifact.url -OutFile $path }
}

foreach ($prop in $assetIndex.objects.PSObject.Properties) {
    if ($prop.Name -match "^minecraft/(sounds|lang)/") { continue }
    $dir  = "assets\objects\$($prop.Value.hash.Substring(0,2))"
    $path = "$dir\$($prop.Value.hash)"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
    if (-not (Test-Path $path)) { Invoke-WebRequest "https://resources.download.minecraft.net/$($prop.Value.hash.Substring(0,2))/$($prop.Value.hash)" -OutFile $path }
}

$cp = ((gci -R -Fi *.jar | % { $_.FullName }) -join ";") + ";client.jar"

java -cp $cp net.minecraft.client.main.Main --version 1.21.10 -assetIndex 27 --uuid $login.profile.id --username $login.profile.name --accessToken $login.token
