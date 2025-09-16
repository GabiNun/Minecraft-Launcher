if (-not (gcm java -Ea 0)) {
    Write-Host "Java not found. Installing Oracle JDK 21..."
    winget install --id Oracle.JDK.21 -e
}
