irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Get-Java.ps1 | iex
$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path "$env:APPDATA\.minecraft")) {
    ni $env:APPDATA\.minecraft\assets\indexes -I D | Out-Null
}
Set-Location $env:APPDATA\.minecraft

if (Test-Path login.json) {
    $login = Get-Content login.json -Raw | ConvertFrom-Json
} else {
    irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/Microsoft-Login.ps1 | iex
}

if (-not (Test-Path "client.jar")) {
    Invoke-WebRequest "https://piston-data.mojang.com/v1/objects/a19d9badbea944a4369fd0059e53bf7286597576/client.jar" -OutFile "client.jar"
}

Invoke-WebRequest "https://piston-meta.mojang.com/v1/packages/7db0407a8e9e9a0520b5e3ecba3a3e4650169cd6/26.json" -OutFile "assets\indexes\26.json"
$json = Invoke-RestMethod "https://piston-meta.mojang.com/v1/packages/db4d7600e0d402a7ba7ad16ce748098f4c704d75/1.21.8.json"
foreach ($lib in $json.libraries) {
    if ($null -ne $lib.downloads.artifact -and $lib.downloads.artifact.url -and $lib.downloads.artifact.path) {
        $dest = Join-Path -Path "libraries" -ChildPath $lib.downloads.artifact.path
        $folder = Split-Path $dest -Parent
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Force -Path $folder | Out-Null
        }
        Invoke-WebRequest $lib.downloads.artifact.url -OutFile $dest
    }
}

$assetIndex = Get-Content "assets\indexes\26.json" | ConvertFrom-Json

foreach ($entry in $assetIndex.objects.PSObject.Properties) {
    if ($entry.Name -like "minecraft/sounds/*") { continue }
    $path = "assets\objects\" + $entry.Value.hash.Substring(0,2) + "\" + $entry.Value.hash
    if (-not (Test-Path (Split-Path $path -Parent))) { New-Item -ItemType Directory -Force -Path (Split-Path $path -Parent) | Out-Null }
    if (-not (Test-Path $path)) {
        Invoke-WebRequest ("https://resources.download.minecraft.net/" + $entry.Value.hash.Substring(0,2) + "/" + $entry.Value.hash) -OutFile $path
    }
}

$cp = ((gci -R -Fi *.jar | % { $_.FullName }) -join ";") + ";client.jar"

java -cp $cp net.minecraft.client.main.Main --version 1.21.8 --assetsDir assets -assetIndex 26 --uuid $login.profile.id --username $login.profile.name --accessToken $login.token
