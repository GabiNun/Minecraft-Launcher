$JavaInstalled = $false
if (Get-Command java -Ea 0) {
    $JavaInstalled = $true
}

if false {
 winget install Oracle.JDK.21
}
