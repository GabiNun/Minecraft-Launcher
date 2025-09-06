# Microsoft Login Authentication for Minecraft Launcher

function Get-Microsoft-Minecraft-Identity {

    Start-Process "https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&redirect_uri=https://login.live.com/oauth20_desktop.srf&scope=XboxLive.signin offline_access"
    $code = Read-Host "`nPaste ONLY the code from the browser's URL after login (the value after 'code=')"

    $access = (irm -Method Post -Uri "https://login.live.com/oauth20_token.srf" -Body @{
        client_id="00000000402b5328"
        grant_type="authorization_$code"
        redirect_uri="https://login.live.com/oauth20_desktop.srf"
    }).access_token

    $xblToken = (irm -Method Post -Uri "https://user.auth.xboxlive.com/user/authenticate" -Headers @{ "Content-Type"="application/json" } -Body (@{
        Properties = @{
            AuthMethod="RPS"
            SiteName="user.auth.xboxlive.com"
            RpsTicket="d=$access"
        }
        RelyingParty="http://auth.xboxlive.com"
        TokenType="JWT"
    } | ConvertTo-Json)).Token

    $xsts = irm -Method Post -Uri "https://xsts.auth.xboxlive.com/xsts/authorize" -Headers @{ "Content-Type"="application/json" } -Body (@{
        Properties = @{
            SandboxId="RETAIL"
            UserTokens=@($xblToken)
        }
        RelyingParty="rp://api.minecraftservices.com/"
        TokenType="JWT"
    } | ConvertTo-Json)
    $identity = "XBL3.0 x=$($xsts.DisplayClaims.xui[0].uhs);$($xsts.Token)"

    $token = (irm -Method Post -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Headers @{ "Content-Type"="application/json" } -Body (@{identityToken=$identity} | ConvertTo-Json)).access_token
    $profile = irm "https://api.minecraftservices.com/minecraft/profile" -Headers @{Authorization="Bearer $token"}

    Set-Content $loginFile -Value (@{token=$token; profile=$profile} | ConvertTo-Json -Depth 6)
    return @{token=$token;profile=$profile}
}
