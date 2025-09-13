$ClientId = "ec859e96-84d8-4375-a43f-2d7d949d2ded"
$Tenant = "consumers"
$Scopes = "XboxLive.signin offline_access openid profile"
$deviceUri = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/devicecode"
$tokenUri = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token"
$deviceResp = Invoke-RestMethod -Method Post -Uri $deviceUri -ContentType 'application/x-www-form-urlencoded' -Body @{client_id=$ClientId; scope=$Scopes}
Write-Host $deviceResp.message
$openUrl = $deviceResp.verification_uri_complete
if (-not $openUrl) { $openUrl = $deviceResp.verification_uri }
if ($openUrl) { Start-Process $openUrl }
$expiresAt = (Get-Date).AddSeconds([int]$deviceResp.expires_in)
$interval = [int]$deviceResp.interval
$token = $null
while ((Get-Date) -lt $expiresAt) {
    Start-Sleep -Seconds $interval
    try {
        $token = Invoke-RestMethod -Method Post -Uri $tokenUri -ContentType 'application/x-www-form-urlencoded' -Body @{
            grant_type = 'urn:ietf:params:oauth:grant-type:device_code'
            client_id  = $ClientId
            device_code = $deviceResp.device_code
        }
        break
    } catch {
        $resp = $_.Exception.Response
        if ($resp -ne $null) {
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $content = $reader.ReadToEnd()
            try { $err = $content | ConvertFrom-Json } catch { $err = $null }
            if ($err -and $err.error) {
                if ($err.error -eq 'authorization_pending') { continue }
                if ($err.error -eq 'slow_down') { $interval += 5; continue }
                if ($err.error -eq 'expired_token') { Write-Error 'Device code expired. Restart process.' ; exit 1 }
                Write-Error "Token error: $($err.error) - $($err.error_description)"
                exit 1
            } else {
                Write-Error "Unexpected token endpoint response: $content"
                exit 1
            }
        } else {
            Write-Error $_.Exception.Message
            exit 1
        }
    }
}
if (-not $token) { Write-Error "No token received. Make sure you completed the browser sign-in within the time window."; exit 1 }
$msAccessToken = $token.access_token
Write-Host "Got Microsoft access token."
$headers = @{ 'Content-Type' = 'application/json'; 'Accept' = 'application/json' }
$body = @{
    Properties = @{
        AuthMethod = "RPS"
        SiteName = "user.auth.xboxlive.com"
        RpsTicket = "d=$msAccessToken"
    }
    RelyingParty = "http://auth.xboxlive.com"
    TokenType = "JWT"
} | ConvertTo-Json -Depth 10
$xblResp = Invoke-RestMethod -Uri 'https://user.auth.xboxlive.com/user/authenticate' -Method Post -Headers $headers -Body $body
$xblToken = $xblResp.Token
$uhs = $xblResp.DisplayClaims.xui[0].uhs
Write-Host "Got Xbox Live token."
$xstsBody = @{
    Properties = @{
        SandboxId = "RETAIL"
        UserTokens = @($xblToken)
    }
    RelyingParty = "rp://api.minecraftservices.com/"
    TokenType = "JWT"
} | ConvertTo-Json -Depth 10
$xstsResp = Invoke-RestMethod -Uri 'https://xsts.auth.xboxlive.com/xsts/authorize' -Method Post -Headers $headers -Body $xstsBody
$xstsToken = $xstsResp.Token
Write-Host "Got XSTS token."
$identityToken = "XBL3.0 x=$uhs;$xstsToken"
$mcBody = @{ identityToken = $identityToken } | ConvertTo-Json -Depth 6
$mcResp = Invoke-RestMethod -Uri 'https://api.minecraftservices.com/authentication/login_with_xbox' -Method Post -Headers @{ 'Content-Type' = 'application/json' } -Body $mcBody
$mcAccessToken = $mcResp.access_token
$mcExpiresIn = $mcResp.expires_in
Write-Host "Got Minecraft access token."
$entitlements = Invoke-RestMethod -Uri 'https://api.minecraftservices.com/entitlements/mcstore' -Headers @{ Authorization = "Bearer $mcAccessToken" } -Method Get
$profile = Invoke-RestMethod -Uri 'https://api.minecraftservices.com/minecraft/profile' -Headers @{ Authorization = "Bearer $mcAccessToken" } -Method Get
$result = [PSCustomObject]@{
    MSAccessToken = $msAccessToken
    XBLToken = $xblToken
    XSTSToken = $xstsToken
    MinecraftAccessToken = $mcAccessToken
    MinecraftExpiresIn = $mcExpiresIn
    Entitlements = $entitlements
    Profile = $profile
}
$result | Format-List
