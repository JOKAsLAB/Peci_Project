[CmdletBinding()]
param(
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [int]$StartupTimeoutSeconds = 45,
    [string]$Email = "admin@ua.pt",
    [System.Security.SecureString]$Password,
    [switch]$SkipEnsureBackend
)

$ErrorActionPreference = "Stop"

$testDir = $PSScriptRoot
$scriptsDir = Split-Path -Parent $testDir
$ensureBackendScript = Join-Path $scriptsDir "run\ensure_admin_docente_backend.ps1"

function Get-HttpStatusCode {
    param($Exception)

    try {
        if ($Exception -and $Exception.Response -and $Exception.Response.StatusCode) {
            return [int]$Exception.Response.StatusCode
        }
    }
    catch {
        return -1
    }

    return -1
}

if (-not $SkipEnsureBackend) {
    & $ensureBackendScript -BaseUrl $BaseUrl -StartupTimeoutSeconds $StartupTimeoutSeconds -CookieMode local
    if ($LASTEXITCODE -ne 0) {
        throw "Backend bootstrap failed before cookie auth check."
    }
}

$resolvedPassword = if ($Password) {
    [System.Net.NetworkCredential]::new("", $Password).Password
}
else {
    "admin123"
}

$loginPayload = @{
    email = $Email
    password = $resolvedPassword
} | ConvertTo-Json

$baseUri = [uri]$BaseUrl
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

try {
    $loginResponse = Invoke-WebRequest -Uri "$BaseUrl/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginPayload -WebSession $session -UseBasicParsing
}
catch {
    $statusCode = Get-HttpStatusCode -Exception $_.Exception

    if ($statusCode -notin @(401, 403)) {
        throw "Login request failed with status code $statusCode. $($_.Exception.Message)"
    }

    $registerPayload = @{
        name = "Admin Script"
        email = $Email
        password = $resolvedPassword
        role = "Admin"
    } | ConvertTo-Json

    try {
        Invoke-WebRequest -Uri "$BaseUrl/api/v1/auth/register" -Method POST -ContentType "application/json" -Body $registerPayload -WebSession $session -UseBasicParsing | Out-Null
    }
    catch {
        $registerStatus = Get-HttpStatusCode -Exception $_.Exception
        if ($registerStatus -ne 409) {
            throw "Could not create admin account for cookie check. Status: $registerStatus. $($_.Exception.Message)"
        }
    }

    $loginResponse = Invoke-WebRequest -Uri "$BaseUrl/api/v1/auth/login" -Method POST -ContentType "application/json" -Body $loginPayload -WebSession $session -UseBasicParsing
}

if ($loginResponse.StatusCode -ne 200) {
    throw "Login failed during cookie check. HTTP $($loginResponse.StatusCode)."
}

$cookies = $session.Cookies.GetCookies($baseUri)
if ($cookies.Count -le 0) {
    throw "No cookies were stored in session after login."
}

$authCookie = $cookies | Where-Object { $_.Name -eq "peci_access_token" } | Select-Object -First 1
if (-not $authCookie) {
    throw "Expected auth cookie 'peci_access_token' was not found after login."
}

$meResponse = Invoke-WebRequest -Uri "$BaseUrl/api/v1/auth/me" -Method GET -WebSession $session -UseBasicParsing
if ($meResponse.StatusCode -ne 200) {
    throw "Cookie-based /auth/me check failed with HTTP $($meResponse.StatusCode)."
}

$me = $meResponse.Content | ConvertFrom-Json
if (-not $me.id -or -not $me.email -or -not $me.role) {
    throw "Cookie-based /auth/me response does not match expected user shape."
}

$logoutResponse = Invoke-WebRequest -Uri "$BaseUrl/api/v1/auth/logout" -Method POST -WebSession $session -UseBasicParsing
if ($logoutResponse.StatusCode -ne 200) {
    throw "Logout failed with HTTP $($logoutResponse.StatusCode)."
}

Write-Host "Cookie auth check passed (login -> cookie -> /me -> logout)."
