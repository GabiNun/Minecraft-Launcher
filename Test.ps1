$manifest = irm "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
$latestReleaseUrl = ($manifest.versions | Where-Object { $_.id -eq $manifest.latest.release }).url
$assetIndex = irm (irm $latestReleaseUrl).assetIndex.url

foreach ($entry in $assetIndex.objects.psobject.Properties) {
    $path = $entry.Name
    if ($path -like "minecraft/sounds/*" -or $path -eq "minecraft/sounds.json") { continue }
    if ($path -like "minecraft/lang/*" -and $path -ne "minecraft/lang/en_us.json") { continue }
    $hash = $entry.Value.hash
    $subDir = $hash.Substring(0, 2)
    $url = "https://resources.download.minecraft.net/$subDir/$hash"
    $outPath = Join-Path -Path "assets" -ChildPath $path
    New-Item -ItemType Directory -Path (Split-Path $outPath) -Force | Out-Null
    Invoke-WebRequest -Uri $url -OutFile $outPath
}
