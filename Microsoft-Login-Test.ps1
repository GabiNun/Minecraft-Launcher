$clientId = "ec859e96-84d8-4375-a43f-2d7d949d2ded"
$scope = "XboxLive.signin offline_access"

# Step 1: Request device code
$deviceCodeResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode" -Method POST -Body @{
    client_id = $clientId
    scope = $scope
}

Write-Host "Go to $($deviceCodeResponse.verification_uri)"
Write-Host "Enter this code: $($deviceCodeResponse.user_code)"

# Step 2: Poll for token
$token = $null
while (-not $token) {
    Start-Sleep -Seconds $deviceCodeResponse.interval
    try {
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/token" -Method POST -Body @{
            grant_type = "urn:ietf:params:oauth:grant-type:device_code"
            client_id = $clientId
            device_code = $deviceCodeResponse.device_code
        }
        $token = $tokenResponse.access_token
    } catch {
        # Ignore authorization_pending errors
        if ($_.Exception.Response.StatusCode -ne 400) { throw $_ }
    }
}

Write-Host "Microsoft access token obtained."

# Step 3: Xbox Live auth
$xblBody = @{
    Properties = @{
        AuthMethod = "RPS"
        SiteName = "user.auth.xboxlive.com"
        RpsTicket = "d=$token"
    }
    RelyingParty = "http://auth.xboxlive.com"
    TokenType = "JWT"
}
$xblResponse = Invoke-RestMethod -Uri "https://user.auth.xboxlive.com/user/authenticate" -Method POST -Body ($xblBody | ConvertTo-Json -Depth 10) -ContentType "application/json"
$xblToken = $xblResponse.Token
$uhs = $xblResponse.DisplayClaims.xui[0].uhs

# Step 4: Minecraft auth
$mcBody = @{ identityToken = "XBL3.0 x=$uhs;$xblToken" }
$mcResponse = Invoke-RestMethod -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Method POST -Body ($mcBody | ConvertTo-Json) -ContentType "application/json"
$mcToken = $mcResponse.access_token

# Step 5: Get Minecraft profile
$headers = @{ Authorization = "Bearer $mcToken" }
$profile = Invoke-RestMethod -Uri "https://api.minecraftservices.com/minecraft/profile" -Headers $headers

Write-Host "`n===== MINECRAFT ACCOUNT INFO ====="
Write-Host "Username: $($profile.name)"
Write-Host "UUID: $($profile.id)"
Write-Host "Access Token: $mcToken"
