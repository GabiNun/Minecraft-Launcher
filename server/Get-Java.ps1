if (-not (gcm java -Ea 0)) {
    Write-Host "Java not found. Installing Java"
    winget install --id Oracle.JDK.25 -e
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}
#test
