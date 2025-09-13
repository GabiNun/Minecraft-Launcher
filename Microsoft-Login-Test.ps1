# === CONFIG ===
$clientId = "79422ab0-622b-4fbe-834b-8f964e0ce0af" # Your Azure app client ID
$scope = "XboxLive.signin offline_access"

# === STEP 1: Microsoft Device Code Login ===
$deviceCodeResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode" -Method Post -Body @{
    client_id = $clientId
    scope = $scope
}

# Open the verification URL automatically
$verificationUrl = $deviceCodeResponse.verification_uri
Start-Process $verificationUrl
Write-Host "A browser opened. Enter this code if prompted: $($deviceCodeResponse.user_code)"

# Poll for Microsoft access token
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
        # Waiting for user login
    }
}

Write-Host "Microsoft login complete!"

# === STEP 2: Xbox Live Authentication ===
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

# === STEP 3: XSTS Authentication ===
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

# === STEP 4: Minecraft Access Token ===
$mcBody = @{
    identityToken = "XBL3.0 x=$userHash;$xstsToken"
} | ConvertTo-Json

$mcResponse = Invoke-RestMethod -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Method Post -Body $mcBody -ContentType "application/json"
$mcAccessToken = $mcResponse.access_token

# === STEP 5: Minecraft Profile ===
$profile = Invoke-RestMethod -Uri "https://api.minecraftservices.com/minecraft/profile" -Headers @{ Authorization = "Bearer $mcAccessToken" }

Write-Host "=== Minecraft Login Info ==="
Write-Host "Username: $($profile.name)"
Write-Host "UUID: $($profile.id)"
Write-Host "Access Token: $mcAccessToken"
