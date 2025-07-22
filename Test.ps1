$manifest = Invoke-RestMethod -Uri "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
$latestReleaseId = $manifest.latest.release
$latestReleaseUrl = ($manifest.versions | Where-Object { $_.id -eq $latestReleaseId }).url

$versionData = Invoke-RestMethod -Uri $latestReleaseUrl
