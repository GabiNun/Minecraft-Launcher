$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path "$env:APPDATA\.minecraft")) {
    ni $env:APPDATA\.minecraft -ItemType Directory | Out-Null
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

$assetIndex = Invoke-RestMethod "https://piston-meta.mojang.com/v1/packages/7db0407a8e9e9a0520b5e3ecba3a3e4650169cd6/26.json"
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

foreach ($entry in $assetIndex.objects.PSObject.Properties) {
    if (-not (Test-Path ("assets\objects\" + $entry.Value.hash.Substring(0,2)))) {
        New-Item -ItemType Directory -Force -Path ("assets\objects\" + $entry.Value.hash.Substring(0,2)) | Out-Null
    }
    Invoke-WebRequest -Uri ("https://resources.download.minecraft.net/" + $entry.Value.hash.Substring(0,2) + "/" + $entry.Value.hash) -OutFile ("assets\objects\" + $entry.Value.hash.Substring(0,2) + "\" + $entry.Value.hash)
}

$cp = ((gci -R -Fi *.jar | % { $_.FullName }) -join ";") + ";client.jar"

java -cp $cp net.minecraft.client.main.Main --version 1.21.8 --uuid $login.profile.id --username $login.profile.name --accessToken $login.token
