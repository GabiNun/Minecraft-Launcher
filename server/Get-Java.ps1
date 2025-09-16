$JavaInstalled = $false
if (Get-Command java -Ea 0) {
    $JavaInstalled = $true
}
