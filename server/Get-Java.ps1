if (-not (gcm java -Ea 0)) {
    Write-Host "Java not found. Installing Java 24"
    winget install --id Oracle.JDK.24 -e
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}
