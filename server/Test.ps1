#              irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Test.ps1 | iex

# Variables
$tenantId = "ea3b1daf-a836-4b75-abac-e38ea3cec163"
$clientId = "66cf6e5a-b98b-4e05-b2bd-568d6e30828e"
$clientSecret = "BpC8Q~FdVflzQWMpaP16MS1VaoH5_4lEsgWrtaxP"  # Your client secret
$redirectUri = "http://localhost"  # Your redirect URI

# Function to get an authorization code
function Get-AuthorizationCode {
    param (
        [string]$tenantId,
        [string]$clientId,
        [string]$redirectUri
    )

    $authorizeUri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize?"
    $authorizeUri += "client_id=$clientId"
    $authorizeUri += "&response_type=code"
    $authorizeUri += "&redirect_uri=$redirectUri"
    $authorizeUri += "&response_mode=query"
    $authorizeUri += "&scope=https://graph.microsoft.com/.default"
    $authorizeUri += "https://api.minecraftservices.com/minecraft/profile"

    Start-Process $authorizeUri
    Write-Output "Please authorize the application and copy the full redirect URI from your browser."
    $redirectUriWithCode = Read-Host "Paste the full redirect URI here"
    return $redirectUriWithCode
}

# Function to get an access token
function Get-AccessToken {
    param (
        [string]$tenantId,
        [string]$clientId,
        [string]$clientSecret,
        [string]$redirectUri,
        [string]$authorizationCode
    )

    $body = @{
        client_id     = $clientId
        scope         = "https://graph.microsoft.com/.default https://api.minecraftservices.com/minecraft/profile"
        client_secret = $clientSecret
        grant_type    = "authorization_code"
        code          = $authorizationCode
        redirect_uri  = $redirectUri
    }

    $response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method Post -Body $body
    return $response.access_token
}

# Function to get user information
function Get-UserInformation {
    param (
        [string]$accessToken
    )

    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Method Get -Headers $headers
        return $response
    } catch {
        Write-Error "Error retrieving user information: $_"
    }
}

# Function to get Minecraft information
function Get-MinecraftInformation {
    param (
        [string]$accessToken
    )

    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    try {
        $response = Invoke-RestMethod -Uri "https://api.minecraftservices.com/minecraft/profile" -Method Get -Headers $headers
        return $response
    } catch {
        Write-Error "Error retrieving Minecraft information: $_"
    }
}

# Main script
$authorizationCode = Get-AuthorizationCode -tenantId $tenantId -clientId $clientId -redirectUri $redirectUri
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret -redirectUri $redirectUri -authorizationCode $authorizationCode

if ($accessToken) {
    $userInfo = Get-UserInformation -accessToken $accessToken
    if ($userInfo) {
        Write-Output "User Information:"
        Write-Output "Display Name: $($userInfo.displayName)"
        Write-Output "User Principal Name: $($userInfo.userPrincipalName)"
    }

    $minecraftInfo = Get-MinecraftInformation -accessToken $accessToken
    if ($minecraftInfo) {
        Write-Output "Minecraft Information:"
        Write-Output "UUID: $($minecraftInfo.id)"
        Write-Output "Name: $($minecraftInfo.name)"
    }
} else {
    Write-Error "Failed to retrieve access token."
}
