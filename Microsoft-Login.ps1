function Save-LoginFile($token, $profile) {
    Set-Content $loginFile -Value (@{token=$token;profile=$profile} | ConvertTo-Json -Depth 6)
}

function Load-LoginFile {
    if (Test-Path $loginFile) {
        try {
            return (Get-Content $loginFile -Raw | ConvertFrom-Json)
        } catch { return $null }
    }
    return $null
}

function Is-Token-Valid($token) {
    if ($token) {
        try {
            Invoke-RestMethod "https://api.minecraftservices.com/minecraft/profile" -Headers @{Authorization="Bearer $token"} -ErrorAction Stop | Out-Null
            return $true
        } catch { return $false }
    }
    return $false
}

function Get-Microsoft-Minecraft-Identity {
    $login = Load-LoginFile
    if ($login -and (Is-Token-Valid $login.token)) {
        Write-Host "Using saved login file!" -ForegroundColor Green
        return $login
    }

    Start-Process "https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&redirect_uri=https://login.live.com/oauth20_desktop.srf&scope=XboxLive.signin offline_access"
    $code = Read-Host "`nPaste ONLY the code from the browser's URL after login (the value after 'code=')"

    $access = (Invoke-RestMethod -Method Post -Uri "https://login.live.com/oauth20_token.srf" -Body @{
        client_id="00000000402b5328"
        code=$code
        grant_type="authorization_code"
        redirect_uri="https://login.live.com/oauth20_desktop.srf"
    }).access_token

    $xblToken = (Invoke-RestMethod -Method Post -Uri "https://user.auth.xboxlive.com/user/authenticate" -Headers @{ "Content-Type"="application/json" } -Body (@{
        Properties = @{
            AuthMethod="RPS"
            SiteName="user.auth.xboxlive.com"
            RpsTicket="d=$access"
        }
        RelyingParty="http://auth.xboxlive.com"
        TokenType="JWT"
    } | ConvertTo-Json)).Token

    $xsts = Invoke-RestMethod -Method Post -Uri "https://xsts.auth.xboxlive.com/xsts/authorize" -Headers @{ "Content-Type"="application/json" } -Body (@{
        Properties = @{
            SandboxId="RETAIL"
            UserTokens=@($xblToken)
        }
        RelyingParty="rp://api.minecraftservices.com/"
        TokenType="JWT"
    } | ConvertTo-Json)
    $identity = "XBL3.0 x=$($xsts.DisplayClaims.xui[0].uhs);$($xsts.Token)"

    $token = (Invoke-RestMethod -Method Post -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Headers @{ "Content-Type"="application/json" } -Body (@{identityToken=$identity} | ConvertTo-Json)).access_token
    $profile = Invoke-RestMethod "https://api.minecraftservices.com/minecraft/profile" -Headers @{Authorization="Bearer $token"}

    Save-LoginFile $token $profile
    return @{token=$token;profile=$profile}
}
