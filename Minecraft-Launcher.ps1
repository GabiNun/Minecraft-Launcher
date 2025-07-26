irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/Downloader.ps1 | iex

$classpathString = [string]::Join(';', (Get-ChildItem "$env:APPDATA\.minecraft\libraries" -Recurse -Filter *.jar | ForEach-Object FullName) + "$env:APPDATA\.minecraft\client.jar")

$args = @(
    "--version", $latestReleaseData.id,
    "--gameDir", "$env:APPDATA\.minecraft",
    "--assetsDir", "$env:APPDATA\.minecraft\assets",
    "--assetIndex", $latestReleaseData.assets,
    "--uuid", "00000000-0000-0000-0000-000000000000",
    "--username", "Player",
    "--versionType", "release",
    "--accessToken", "0",
    "--userType", "legacy"
)

java -cp $classpathString net.minecraft.client.main.Main $args
