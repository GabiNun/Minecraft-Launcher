function Get-Microsoft-Minecraft-Identity {
    Start-Process "https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&redirect_uri=https://login.live.com/oauth20_desktop.srf&scope=XboxLive.signin offline_access"
    $code = Read-Host "`nPaste value after code= and before &lc=1033)"

    $xsts = (Invoke-RestMethod -Method Post -Uri "https://xsts.auth.xboxlive.com/xsts/authorize" -Headers @{ "Content-Type"="application/json" } -Body ((Invoke-RestMethod -Method Post -Uri "https://user.auth.xboxlive.com/user/authenticate" -Headers @{ "Content-Type"="application/json" } -Body (@{
        Properties = @{ AuthMethod="RPS"; SiteName="user.auth.xboxlive.com"; RpsTicket="d=$((Invoke-RestMethod -Method Post -Uri 'https://login.live.com/oauth20_token.srf' -Body @{client_id='00000000402b5328'; code=$code; grant_type='authorization_code'; redirect_uri='https://login.live.com/oauth20_desktop.srf'}).access_token)" }
        RelyingParty="http://auth.xboxlive.com"
        TokenType="JWT"
    } | ConvertTo-Json))).Token) | ConvertTo-Json

    $identity="XBL3.0 x=$($xsts.DisplayClaims.xui[0].uhs);$($xsts.Token)"
    $token=(Invoke-RestMethod -Method Post -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Headers @{ "Content-Type"="application/json" } -Body (@{identityToken=$identity} | ConvertTo-Json)).access_token
    Set-Content $loginFile -Value (@{token=$token; profile=(Invoke-RestMethod "https://api.minecraftservices.com/minecraft/profile" -Headers @{Authorization="Bearer $token"})} | ConvertTo-Json -Depth 6)
}
