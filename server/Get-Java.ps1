if (-not (gcm java -Ea 0)) {
    winget install Oracle.JDK.25
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}
