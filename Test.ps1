$manifest = irm piston-meta.mojang.com/mc/game/version_manifest_v2.json
$latestReleaseUrl = ($manifest.versions | ? id -eq $manifest.latest.release).url

$versionData = irm $latestReleaseUrl
irm $versionData.downloads.client.url -OutFile client.jar
