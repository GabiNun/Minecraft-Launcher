# -----------------------------
# 1. Microsoft Device Code Flow
# -----------------------------
$tenantId = "common"  # Can use "common" for Microsoft accounts
$clientId = "ec859e96-84d8-4375-a43f-2d7d949d2ded"

$deviceCodeResponse = Invoke-RestMethod -Method Post `
    -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        client_id = $clientId
        scope     = "XboxLive.signin offline_access"
    }

Start-Process $deviceCodeResponse.verification_uri
Write-Host "Open the browser and enter the code: $($deviceCodeResponse.user_code)"

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

$msAccessToken = $tokenResponse.access_token
Write-Host "`nMicrosoft Access Token acquired.`n"

# -----------------------------
# 2. Xbox Live Login
# -----------------------------
$bodyXBL = @{
    Properties = @{
        AuthMethod = "RPS"
        SiteName   = "user.auth.xboxlive.com"
        RpsTicket  = "d=$msAccessToken"
    }
    RelyingParty = "http://auth.xboxlive.com"
    TokenType    = "JWT"
} | ConvertTo-Json -Depth 5

$xblResponse = Invoke-RestMethod -Method Post `
    -Uri "https://user.auth.xboxlive.com/user/authenticate" `
    -ContentType "application/json" `
    -Body $bodyXBL

$xblToken = $xblResponse.Token
$uhs = $xblResponse.DisplayClaims.xui[0].uhs
Write-Host "Xbox Live token acquired."

# -----------------------------
# 3. XSTS Authorization
# -----------------------------
$bodyXSTS = @{
    Properties = @{
        SandboxId = "RETAIL"
        UserTokens = @($xblToken)
    }
    RelyingParty = "rp://api.minecraftservices.com/"
    TokenType    = "JWT"
} | ConvertTo-Json -Depth 5

$xstsResponse = Invoke-RestMethod -Method Post `
    -Uri "https://xsts.auth.xboxlive.com/xsts/authorize" `
    -ContentType "application/json" `
    -Body $bodyXSTS

$xstsToken = $xstsResponse.Token
Write-Host "XSTS token acquired."

# -----------------------------
# 4. Minecraft Login
# -----------------------------
$bodyMinecraft = @{
    identityToken = "XBL3.0 x=$uhs;$xstsToken"
} | ConvertTo-Json

$mcResponse = Invoke-RestMethod -Method Post `
    -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" `
    -ContentType "application/json" `
    -Body $bodyMinecraft

# Get Minecraft access token
$mcAccessToken = $mcResponse.access_token

# -----------------------------
# 5. Get Minecraft Profile (UUID & username)
# -----------------------------
$mcProfile = Invoke-RestMethod -Method Get `
    -Uri "https://api.minecraftservices.com/minecraft/profile" `
    -Headers @{ Authorization = "Bearer $mcAccessToken" }

$Username = $mcProfile.name
$uuid = $mcProfile.id

Write-Host "`nMinecraft Access Token:`n$mcAccessToken"
Write-Host "`nMinecraft Username: $Username"
Write-Host "Minecraft UUID: $uuid"
