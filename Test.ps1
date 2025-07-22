$manifest = Invoke-RestMethod -Uri piston-meta.mojang.com/mc/game/version_manifest_v2.json
$latestReleaseUrl = ($manifest.versions | ? { $_.id -eq $manifest.latest.release }).url
