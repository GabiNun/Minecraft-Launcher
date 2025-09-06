function Get-Microsoft-Minecraft-Identity {

    $clientId = "00000000402b5328"
    $redirectUri = "https://login.live.com/oauth20_desktop.srf"
    $scope = "XboxLive.signin offline_access"
    $loginUrl = "https://login.live.com/oauth20_authorize.srf?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scope"
    Start-Process "explorer.exe" $loginUrl
    $code = Read-Host "`nPaste the value after code= and before &lc=1033)"
    $tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.live.com/oauth20_token.srf" -Body @{
        client_id    = $clientId
        code         = $code
        grant_type   = "authorization_code"
        redirect_uri = $redirectUri
    }

    $accessToken = $tokenResponse.access_token

    $xblToken = (Invoke-RestMethod -Method Post -Uri "https://user.auth.xboxlive.com/user/authenticate" -Headers @{ "Content-Type" = "application/json" } -Body (@{
        Properties = @{
            AuthMethod = "RPS"
            SiteName   = "user.auth.xboxlive.com"
            RpsTicket  = "d=$accessToken"
        }
        RelyingParty = "http://auth.xboxlive.com"
        TokenType    = "JWT"
    } | ConvertTo-Json -Compress)).Token

    $xstsResponse = Invoke-RestMethod -Method Post -Uri "https://xsts.auth.xboxlive.com/xsts/authorize" -Headers @{ "Content-Type" = "application/json" } -Body (@{
        Properties = @{
            SandboxId  = "RETAIL"
            UserTokens = @($xblToken)
        }
        RelyingParty = "rp://api.minecraftservices.com/"
        TokenType    = "JWT"
    } | ConvertTo-Json -Compress)

    $identity = "XBL3.0 x=$($xstsResponse.DisplayClaims.xui[0].uhs);$($xstsResponse.Token)"
    $mcToken = (Invoke-RestMethod -Method Post -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Headers @{ "Content-Type" = "application/json" } -Body (@{ identityToken = $identity } | ConvertTo-Json -Compress)).access_token
    $profile = Invoke-RestMethod "https://api.minecraftservices.com/minecraft/profile" -Headers @{ Authorization = "Bearer $mcToken" }
    Set-Content $loginFile -Value (@{ token = $mcToken; profile = $profile } | ConvertTo-Json -Depth 4)
}
