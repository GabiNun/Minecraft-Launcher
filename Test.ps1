$manifest = irm launchermeta.mojang.com/mc/game/version_manifest.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url
$latestReleaseData = irm $latestReleaseUrl
