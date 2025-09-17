$ProgressPreference = 'SilentlyContinue'

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

if (-not (Test-Path "client.jar")) {
    Invoke-WebRequest "https://piston-data.mojang.com/v1/objects/a19d9badbea944a4369fd0059e53bf7286597576/client.jar" -OutFile "client.jar"
}
