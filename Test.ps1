$manifest = irm "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
$latestReleaseUrl = ($manifest.versions | Where-Object { $_.id -eq $manifest.latest.release }).url
