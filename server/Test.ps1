#              irm raw.githubusercontent.com/GabiNun/Minecraft-Launcher/main/server/Test.ps1 | iex

param (
    [string]$ClientId = 'ec859e96-84d8-4375-a43f-2d7d949d2ded',
    [string]$Tenant = 'consumers'
)

# Azure portal (for app management / API permissions):
# https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade

$deviceCodeEndpoint = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/devicecode"
$tokenEndpoint = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token"
$scopes = 'XboxLive.signin offline_access openid'

$deviceResp = Invoke-RestMethod -Method Post -Uri $deviceCodeEndpoint -Body @{ client_id = $ClientId; scope = $scopes }
Write-Host "Visit $($deviceResp.verification_uri) and enter code: $($deviceResp.user_code)"

$pollInterval = [int]$deviceResp.interval

do {
    Start-Sleep -Seconds $pollInterval
    try {
        $tokenResp = Invoke-RestMethod -Method Post -Uri $tokenEndpoint -Body @{
            client_id    = $ClientId
            grant_type   = 'urn:ietf:params:oauth:grant-type:device_code'
            device_code  = $deviceResp.device_code
        }
        break
    }
    catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 400) {
            $body = $_.Exception.Response.GetResponseStream() |
                   % { New-Object System.IO.StreamReader($_) } |
                   % { $_.ReadToEnd() }
            if ($body -match 'authorization_pending') { continue }
            if ($body -match 'authorization_declined') { throw 'User declined authorization' }
            throw $body
        }
        else { throw $_ }
    }
} while ($true)

$msAccessToken = $tokenResp.access_token

$headers = @{ 'Accept' = 'application/json'; 'Content-Type' = 'application/json' }
$bodyXbox = @{
    Properties = @{
        AuthMethod = 'RPS'
        SiteName   = 'user.auth.xboxlive.com'
        RpsTicket  = $msAccessToken
    }
    RelyingParty = 'http://auth.xboxlive.com'
    TokenType     = 'JWT'
} | ConvertTo-Json -Depth 10

try {
    $xboxResp = Invoke-RestMethod -Method Post -Uri 'https://user.auth.xboxlive.com/user/authenticate' -Headers $headers -Body $bodyXbox
}
catch {
    $bodyXbox2 = $bodyXbox -replace $msAccessToken, ("d=" + $msAccessToken)
    $xboxResp = Invoke-RestMethod -Method Post -Uri 'https://user.auth.xboxlive.com/user/authenticate' -Headers $headers -Body $bodyXbox2
}

$xboxToken = $xboxResp.Token
$userHash  = $xboxResp.DisplayClaims.xui[0].uhs

$xstsBody = @{
    Properties = @{
        SandboxId  = 'RETAIL'
        UserTokens = @($xboxToken)
    }
    RelyingParty = 'rp://api.minecraftservices.com/'
    TokenType     = 'JWT'
} | ConvertTo-Json -Depth 10

$xstsResp = Invoke-RestMethod -Method Post -Uri 'https://xsts.auth.xboxlive.com/xsts/authorize' -Headers $headers -Body $xstsBody
$xstsToken = $xstsResp.Token

$identityToken = "XBL3.0 x=$userHash;$xstsToken"
$mcLoginBody = @{ identityToken = $identityToken } | ConvertTo-Json
$mcResp = Invoke-RestMethod -Method Post -Uri 'https://api.minecraftservices.com/authentication/login_with_xbox' -Headers @{ 'Content-Type' = 'application/json' } -Body $mcLoginBody

$mcAccessToken = $mcResp.access_token

$profile = Invoke-RestMethod -Method Get -Uri 'https://api.minecraftservices.com/minecraft/profile' -Headers @{ Authorization = "Bearer $mcAccessToken" }

Write-Host "Minecraft Access Token: $mcAccessToken"
Write-Host "UUID (Profile ID): $($profile.id)"
Write-Host "Username: $($profile.name)"
