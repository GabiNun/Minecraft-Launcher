#              irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Test.ps1 | iex

# Variables
$tenantId = "ea3b1daf-a836-4b75-abac-e38ea3cec163"
$clientId = "66cf6e5a-b98b-4e05-b2bd-568d6e30828e"
$clientSecret = "BpC8Q~FdVflzQWMpaP16MS1VaoH5_4lEsgWrtaxP"  # Your client secret
$redirectUri = "http://localhost"  # Your redirect URI

# Function to get an access token
function Get-AccessToken {
    param (
        [string]$tenantId,
        [string]$clientId,
        [string]$clientSecret,
        [string]$redirectUri
    )

    $body = @{
        client_id     = $clientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type    = "client_credentials"
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

    $response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Method Get -Headers $headers
    return $response
}

# Function to get Minecraft information
function Get-MinecraftInformation {
    param (
        [string]$accessToken
    )

    $headers = @{
        Authorization = "Bearer $accessToken"
    }

    $response = Invoke-RestMethod -Uri "https://api.minecraftservices.com/minecraft/profile" -Method Get -Headers $headers
    return $response
}

# Main script
$accessToken = Get-AccessToken -tenantId $tenantId -clientId $clientId -clientSecret $clientSecret -redirectUri $redirectUri

$userInfo = Get-UserInformation -accessToken $accessToken
Write-Output "User Information:"
Write-Output "Display Name: $($userInfo.displayName)"
Write-Output "User Principal Name: $($userInfo.userPrincipalName)"

$minecraftInfo = Get-MinecraftInformation -accessToken $accessToken
Write-Output "Minecraft Information:"
Write-Output "UUID: $($minecraftInfo.id)"
Write-Output "Name: $($minecraftInfo.name)"
Write-Output "Access Token: $accessToken"
