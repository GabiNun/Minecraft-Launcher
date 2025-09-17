$ProgressPreference = 'SilentlyContinue'

$json = Invoke-RestMethod -Uri "https://piston-meta.mojang.com/v1/packages/db4d7600e0d402a7ba7ad16ce748098f4c704d75/1.21.8.json"
foreach ($lib in $json.libraries) {
    $artifact = $lib.downloads.artifact
    if ($null -ne $artifact) {
        $url = $artifact.url
        $path = $artifact.path
        if ($url -and $path) {
            $dest = Join-Path -Path "libraries" -ChildPath $path
            $folder = Split-Path $dest -Parent
            if (-not (Test-Path $folder)) {
                New-Item -ItemType Directory -Force -Path $folder | Out-Null
            }
            Invoke-WebRequest -Uri $url -OutFile $dest
        }
    }
}
