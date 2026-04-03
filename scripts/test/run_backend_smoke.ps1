[CmdletBinding()]
param(
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [int]$StartupTimeoutSeconds = 45,
    [switch]$InstallDeps,
    [switch]$RestartBackendIfHealthy,
    [string]$AdminEmail,
    [System.Security.SecureString]$AdminPassword
)

$ErrorActionPreference = "Stop"

$testDir = $PSScriptRoot
$scriptsDir = Split-Path -Parent $testDir
$projectRoot = Split-Path -Parent $scriptsDir
$backendDir = Join-Path $projectRoot "backend\backend"
$ensureBackendScript = Join-Path $scriptsDir "run\ensure_admin_docente_backend.ps1"

if (-not (Test-Path $backendDir)) {
    throw "Backend directory not found: $backendDir"
}

function Get-PythonExecutable {
    $venvPython = Join-Path $projectRoot ".venv\Scripts\python.exe"
    if (Test-Path $venvPython) {
        return $venvPython
    }

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        return $pythonCmd.Source
    }

    throw "Python executable not found."
}

$python = Get-PythonExecutable

& $ensureBackendScript `
    -BaseUrl $BaseUrl `
    -StartupTimeoutSeconds $StartupTimeoutSeconds `
    -CookieMode local `
    -InstallDeps:$InstallDeps `
    -RestartIfHealthy:$RestartBackendIfHealthy

if ($LASTEXITCODE -ne 0) {
    throw "Backend bootstrap failed before smoke tests."
}

$previousSmokeBaseUrl = $env:SMOKE_BASE_URL
$previousSmokeAdminEmail = $env:SMOKE_ADMIN_EMAIL
$previousSmokeAdminPassword = $env:SMOKE_ADMIN_PASSWORD

try {
    $env:SMOKE_BASE_URL = $BaseUrl

    if ($AdminEmail) {
        $env:SMOKE_ADMIN_EMAIL = $AdminEmail
    }
    else {
        Remove-Item Env:SMOKE_ADMIN_EMAIL -ErrorAction SilentlyContinue
    }

    if ($AdminPassword) {
        $resolvedAdminPassword = [System.Net.NetworkCredential]::new("", $AdminPassword).Password
        $env:SMOKE_ADMIN_PASSWORD = $resolvedAdminPassword
    }
    else {
        Remove-Item Env:SMOKE_ADMIN_PASSWORD -ErrorAction SilentlyContinue
    }

    Push-Location $backendDir
    try {
        & $python -m pytest tests/smoke -q -p no:cacheprovider
        if ($LASTEXITCODE -ne 0) {
            throw "Backend smoke tests failed."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    if ($null -eq $previousSmokeBaseUrl) { Remove-Item Env:SMOKE_BASE_URL -ErrorAction SilentlyContinue } else { $env:SMOKE_BASE_URL = $previousSmokeBaseUrl }
    if ($null -eq $previousSmokeAdminEmail) { Remove-Item Env:SMOKE_ADMIN_EMAIL -ErrorAction SilentlyContinue } else { $env:SMOKE_ADMIN_EMAIL = $previousSmokeAdminEmail }
    if ($null -eq $previousSmokeAdminPassword) { Remove-Item Env:SMOKE_ADMIN_PASSWORD -ErrorAction SilentlyContinue } else { $env:SMOKE_ADMIN_PASSWORD = $previousSmokeAdminPassword }
}

Write-Host "Backend smoke tests completed successfully."
