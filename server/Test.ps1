$apiUrl = 'https://authserver.mojang.com'
$uuid = $null

function Get-UUID($value) {
    if (-not $uuid) {
        $uuid = [guid]::NewGuid().ToString()
    }
    return $uuid
}

function Parse-Props($array) {
    if ($array) {
        $obj = @{}
        foreach ($entry in $array) {
            if ($obj.ContainsKey($entry.name)) {
                $obj[$entry.name] += $entry.value
            } else {
                $obj[$entry.name] = @($entry.value)
            }
        }
        return ($obj | ConvertTo-Json -Compress)
    } else {
        return '{}'
    }
}

function Get-Auth($username, $password, $clientToken = $null) {
    $uuid = Get-UUID $username
    if (-not $password) {
        return @{
            access_token = $uuid
            client_token = $clientToken ?? $uuid
            uuid = $uuid
            name = $username
            user_properties = '{}'
        }
    }

    $body = @{
        agent = @{
            name = 'Minecraft'
            version = 1
        }
        username = $username
        password = $password
        clientToken = $uuid
        requestUser = $true
    }

    try {
        $response = Invoke-RestMethod -Uri "$apiUrl/authenticate" -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        if (-not $response.selectedProfile) {
            throw "Validation error"
        }

        return @{
            access_token = $response.accessToken
            client_token = $response.clientToken
            uuid = $response.selectedProfile.id
            name = $response.selectedProfile.name
            selected_profile = $response.selectedProfile
            user_properties = Parse-Props $response.user.properties
        }
    } catch {
        throw $_
    }
}

function Validate($accessToken, $clientToken) {
    $body = @{
        accessToken = $accessToken
        clientToken = $clientToken
    }

    try {
        Invoke-RestMethod -Uri "$apiUrl/validate" -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        return $true
    } catch {
        throw $_
    }
}

function Refresh-Auth($accessToken, $clientToken) {
    $body = @{
        accessToken = $accessToken
        clientToken = $clientToken
        requestUser = $true
    }

    try {
        $response = Invoke-RestMethod -Uri "$apiUrl/refresh" -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        if (-not $response.selectedProfile) {
            throw "Validation error"
        }

        return @{
            access_token = $response.accessToken
            client_token = Get-UUID $response.selectedProfile.name
            uuid = $response.selectedProfile.id
            name = $response.selectedProfile.name
            user_properties = Parse-Props $response.user.properties
        }
    } catch {
        throw $_
    }
}

function Invalidate($accessToken, $clientToken) {
    $body = @{
        accessToken = $accessToken
        clientToken = $clientToken
    }

    try {
        Invoke-RestMethod -Uri "$apiUrl/invalidate" -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        return $true
    } catch {
        throw $_
    }
}

function Sign-Out($username, $password) {
    $body = @{
        username = $username
        password = $password
    }

    try {
        Invoke-RestMethod -Uri "$apiUrl/signout" -Method Post -Body ($body | ConvertTo-Json) -ContentType 'application/json'
        return $true
    } catch {
        throw $_
    }
}

function Change-ApiUrl($url) {
    $global:apiUrl = $url
}

# -------------------------
# INTERACTIVE LOGIN SCRIPT
# -------------------------

$username = Read-Host "Enter your Minecraft email/username"
$passwordSecure = Read-Host "Enter your password" -AsSecureString

# Convert SecureString to plain text
$passwordPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($passwordSecure)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPtr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPtr)

try {
    $user = Get-Auth -username $username -password $password
    Write-Host "Login successful!"
    Write-Host "Username: $($user.name)"
    Write-Host "UUID: $($user.uuid)"
    Write-Host "Access Token: $($user.access_token)"
} catch {
    Write-Host "Login failed: $_"
}
