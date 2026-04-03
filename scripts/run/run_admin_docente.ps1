[CmdletBinding()]
param(
    [string]$BackendBaseUrl = "http://127.0.0.1:8000",
    [int]$BackendStartupTimeoutSeconds = 45,
    [int]$FrontendPort = 5173,
    [switch]$SkipBackendBootstrap,
    [switch]$InstallFrontendDeps,
    [switch]$InstallBackendDeps,
    [switch]$RestartBackendIfHealthy
)

$ErrorActionPreference = "Stop"

$runDir = $PSScriptRoot
$scriptsDir = Split-Path -Parent $runDir
$projectRoot = Split-Path -Parent $scriptsDir
$frontendDir = Join-Path $projectRoot "admin_docente"
$ensureBackendScript = Join-Path $runDir "ensure_admin_docente_backend.ps1"

if (-not (Test-Path $frontendDir)) {
    throw "Frontend directory not found: $frontendDir"
}

if (-not $SkipBackendBootstrap) {
    & $ensureBackendScript `
        -BaseUrl $BackendBaseUrl `
        -StartupTimeoutSeconds $BackendStartupTimeoutSeconds `
        -CookieMode local `
        -InstallDeps:$InstallBackendDeps `
        -RestartIfHealthy:$RestartBackendIfHealthy

    if ($LASTEXITCODE -ne 0) {
        throw "Backend bootstrap failed."
    }
}

Push-Location $frontendDir
try {
    if ($InstallFrontendDeps) {
        npm install
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed in admin_docente"
        }
    }

    $env:VITE_API_BASE_URL = $BackendBaseUrl

    $frontendUrl = "http://127.0.0.1:$FrontendPort"
    Start-Process $frontendUrl | Out-Null

    npm run dev -- --host 127.0.0.1 --port $FrontendPort
}
finally {
    Pop-Location
}
