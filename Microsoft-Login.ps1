# Microsoft Login Authentication for Minecraft Launcher (Classic "just the code" flow)
# Outputs: $mcToken, $mcProfile

function Get-Microsoft-Minecraft-Identity {
    $clientId    = "00000000402b5328"
    $redirectUri = "https://login.live.com/oauth20_desktop.srf"
    $scope       = "XboxLive.signin offline_access"
    $authUrl     = "https://login.live.com/oauth20_authorize.srf?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scope"

    Open-Url $authUrl

    $authCode = Read-Host "`nPaste ONLY the code from the browser's URL after login (the value after 'code=')"

    # Microsoft access token
    $tokenUrl = "https://login.live.com/oauth20_token.srf"
    $body = @{
        client_id    = $clientId
        code         = $authCode
        grant_type   = "authorization_code"
        redirect_uri = $redirectUri
    }
    $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body
    $accessToken = $response.access_token

    # Xbox Live authentication
    $xblAuthUrl = "https://user.auth.xboxlive.com/user/authenticate"
    $xblBody = @{
        Properties = @{
            AuthMethod = "RPS"
            SiteName   = "user.auth.xboxlive.com"
            RpsTicket  = "d=$accessToken"
        }
        RelyingParty = "http://auth.xboxlive.com"
        TokenType    = "JWT"
    } | ConvertTo-Json
    $xblHeaders = @{ "Content-Type" = "application/json" }
    $xblResponse = Invoke-RestMethod -Method Post -Uri $xblAuthUrl -Body $xblBody -Headers $xblHeaders
    $xblToken = $xblResponse.Token

    # XSTS token
    $xstsUrl = "https://xsts.auth.xboxlive.com/xsts/authorize"
    $xstsBody = @{
        Properties = @{
            SandboxId  = "RETAIL"
            UserTokens = @($xblToken)
        }
        RelyingParty = "rp://api.minecraftservices.com/"
        TokenType    = "JWT"
    } | ConvertTo-Json
    $xstsHeaders = @{ "Content-Type" = "application/json" }
    $xstsResponse = Invoke-RestMethod -Method Post -Uri $xstsUrl -Body $xstsBody -Headers $xstsHeaders
    $xstsToken = $xstsResponse.Token
    $uhs = $xstsResponse.DisplayClaims.xui[0].uhs

    # Minecraft access token
    $mcLoginUrl = "https://api.minecraftservices.com/authentication/login_with_xbox"
    $mcBody = @{
        identityToken = "XBL3.0 x=$uhs;$xstsToken"
    } | ConvertTo-Json
    $mcHeaders = @{ "Content-Type" = "application/json" }
    $mcResponse = Invoke-RestMethod -Method Post -Uri $mcLoginUrl -Body $mcBody -Headers $mcHeaders
    $mcToken = $mcResponse.access_token

    # Get Minecraft profile
    $mcProfileUrl = "https://api.minecraftservices.com/minecraft/profile"
    $mcProfileHeaders = @{ "Authorization" = "Bearer $mcToken" }
    $mcProfile = Invoke-RestMethod -Method Get -Uri $mcProfileUrl -Headers $mcProfileHeaders

    Write-Host "`n==== Minecraft Account Info ====" -ForegroundColor Green
    Write-Host "Username: $($mcProfile.name)"
    Write-Host "UUID:     $($mcProfile.id)"
    return @{ token = $mcToken; profile = $mcProfile }
}

$result = Get-Microsoft-Minecraft-Identity
if ($result -ne $null) {
    $mcToken = $result.token
    $mcProfile = $result.profile
} else {
    $mcToken = $null
    $mcProfile = $null
}
