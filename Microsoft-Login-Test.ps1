# Official Minecraft client ID
$clientId = "00000000402b5328"
$scope = "XboxLive.signin offline_access"

# Step 1: Microsoft device code login
$deviceCodeResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode" -Method Post -Body @{
    client_id = $clientId
    scope = $scope
}

# Open remote connect URL automatically (pre-fills the code)
$remoteConnectUrl = "https://login.live.com/oauth20_remoteconnect.srf?otc=$($deviceCodeResponse.device_code)"
Start-Process $remoteConnectUrl
Write-Host "A browser opened. You should be able to log in directly."

# Step 2: Poll for Microsoft access token
$pollInterval = if ($deviceCodeResponse.interval) { $deviceCodeResponse.interval } else { 5 }
$msToken = $null
while (-not $msToken) {
    Start-Sleep -Seconds $pollInterval
    try {
        $tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/token" -Method Post -Body @{
            grant_type = "urn:ietf:params:oauth:grant-type:device_code"
            client_id = $clientId
            device_code = $deviceCodeResponse.device_code
        } -ErrorAction Stop
        $msToken = $tokenResponse.access_token
    } catch {
        # Waiting for login
    }
}

Write-Host "Microsoft login complete!"

# Step 3: Xbox Live authentication
$xblBody = @{
    Properties = @{
        AuthMethod = "RPS"
        SiteName   = "user.auth.xboxlive.com"
        RpsTicket  = "d=$msToken"
    }
    RelyingParty = "http://auth.xboxlive.com"
    TokenType    = "JWT"
} | ConvertTo-Json -Depth 10

$xblResponse = Invoke-RestMethod -Uri "https://user.auth.xboxlive.com/user/authenticate" -Method Post -Body $xblBody -ContentType "application/json"
$xblToken = $xblResponse.Token

# Step 4: XSTS authentication
$xstsBody = @{
    Properties = @{
        SandboxId = "RETAIL"
        UserTokens = @($xblToken)
    }
    RelyingParty = "rp://api.minecraftservices.com/"
    TokenType    = "JWT"
} | ConvertTo-Json -Depth 10

$xstsResponse = Invoke-RestMethod -Uri "https://xsts.auth.xboxlive.com/xsts/authorize" -Method Post -Body $xstsBody -ContentType "application/json"
$xstsToken = $xstsResponse.Token
$userHash = $xstsResponse.DisplayClaims.xui[0].uhs

# Step 5: Minecraft access token
$mcBody = @{
    identityToken = "XBL3.0 x=$userHash;$xstsToken"
} | ConvertTo-Json

$mcResponse = Invoke-RestMethod -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Method Post -Body $mcBody -ContentType "application/json"
$mcAccessToken = $mcResponse.access_token

# Step 6: Minecraft profile
$profile = Invoke-RestMethod -Uri "https://api.minecraftservices.com/minecraft/profile" -Headers @{ Authorization = "Bearer $mcAccessToken" }

Write-Host "=== Minecraft Login Info ==="
Write-Host "Username: $($profile.name)"
Write-Host "UUID: $($profile.id)"
Write-Host "Access Token: $mcAccessToken"
