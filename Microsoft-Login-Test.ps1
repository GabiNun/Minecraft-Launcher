# Configuration
$tenantId = "ea3b1daf-a836-4b75-abac-e38ea3cec163"
$clientId = "ec859e96-84d8-4375-a43f-2d7d949d2ded"

# Step 1: Request a device code
$deviceCodeResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id = $clientId
        scope = "https://graph.microsoft.com/.default offline_access"
    }

# Open the verification URL in the browser automatically
Start-Process $deviceCodeResponse.verification_uri

# Show instructions to the user
Write-Host "A browser window has been opened. Enter the following code if needed: " -ForegroundColor Cyan -NoNewline
Write-Host $deviceCodeResponse.user_code -ForegroundColor Yellow

# Step 2: Poll for access token
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

Write-Host "`nAccess Token:`n$($tokenResponse.access_token)"
