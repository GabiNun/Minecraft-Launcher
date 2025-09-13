$clientId = "YOUR_CLIENT_ID"
$redirectUri = "http://localhost"
$scope = "XboxLive.signin offline_access"

$authUrl = "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scope"
Start-Process $authUrl

$code = Read-Host "Paste the code from the browser URL"

$body = @{
    client_id = $clientId
    redirect_uri = $redirectUri
    grant_type = "authorization_code"
    code = $code
}

$response = Invoke-RestMethod -Uri "https://login.microsoftonline.com/consumers/oauth2/v2.0/token" -Method POST -Body $body
$accessToken = $response.access_token

$body = @{
    Properties = @{
        AuthMethod = "RPS"
        SiteName = "user.auth.xboxlive.com"
        RpsTicket = "d=$accessToken"
    }
    RelyingParty = "http://auth.xboxlive.com"
    TokenType = "JWT"
}

$response = Invoke-RestMethod -Uri "https://user.auth.xboxlive.com/user/authenticate" -Method POST -Body ($body | ConvertTo-Json)
$xblToken = $response.Token

$body = @{
    identityToken = "XBL3.0 x=$($response.DisplayClaims.xui[0].uhs);$xblToken"
}

$response = Invoke-RestMethod -Uri "https://api.minecraftservices.com/authentication/login_with_xbox" -Method POST -Body ($body | ConvertTo-Json) -ContentType "application/json"
$mcToken = $response.access_token

$headers = @{ "Authorization" = "Bearer $mcToken" }
$profile = Invoke-RestMethod -Uri "https://api.minecraftservices.com/minecraft/profile" -Headers $headers

$uuid = $profile.id
$username = $profile.name

Write-Output "Minecraft username: $username"
Write-Output "UUID: $uuid"
