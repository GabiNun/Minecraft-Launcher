# -----------------------------
# Configuration
# -----------------------------
$tenantId = "ea3b1daf-a836-4b75-abac-e38ea3cec163"   # Your Tenant ID
$clientId = "ec859e96-84d8-4375-a43f-2d7d949d2ded" # Your App Client ID
$scope = "https://graph.microsoft.com/.default offline_access" # Permissions your app needs

# -----------------------------
# Step 1: Request a device code
# -----------------------------
$deviceCodeResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id = $clientId
        scope = $scope
    }

# Show instructions to the user
Write-Host $deviceCodeResponse.message

# -----------------------------
# Step 2: Poll for access token
# -----------------------------
$body = @{
    grant_type  = "urn:ietf:params:oauth:grant-type:device_code"
    client_id   = $clientId
    device_code = $deviceCodeResponse.device_code
}

do {
    Start-Sleep -Seconds $deviceCodeResponse.interval
    try {
        $tokenResponse = Invoke-RestMethod -Method Post `
            -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" `
            -ContentType "application/x-www-form-urlencoded" `
            -Body $body
    } catch {
        $tokenResponse = $null
    }
} while (-not $tokenResponse)

# -----------------------------
# Step 3: Use the access token
# -----------------------------
$accessToken = $tokenResponse.access_token
Write-Host "`nAccess Token:`n$accessToken"

# You can now use $accessToken in Authorization headers for Microsoft Graph API calls
