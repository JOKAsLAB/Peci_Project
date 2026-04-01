[CmdletBinding()]
param(
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [int]$StartupTimeoutSeconds = 45,
    [switch]$InstallBackendDeps,
    [switch]$InstallFrontendDeps,
    [switch]$SkipBackendSmoke,
    [switch]$SkipCookieAuth,
    [switch]$SkipFrontendTests,
    [switch]$SkipFrontendUnitTests
)

$ErrorActionPreference = "Stop"

$testDir = $PSScriptRoot
$runBackendSmokeScript = Join-Path $testDir "run_backend_smoke.ps1"
$runCookieAuthScript = Join-Path $testDir "run_cookie_auth_check.ps1"
$runFrontendTestsScript = Join-Path $testDir "run_frontend_admin_docente_tests.ps1"

if (-not $SkipBackendSmoke) {
    & $runBackendSmokeScript `
        -BaseUrl $BaseUrl `
        -StartupTimeoutSeconds $StartupTimeoutSeconds `
        -InstallDeps:$InstallBackendDeps

    if ($LASTEXITCODE -ne 0) {
        throw "Backend smoke suite failed."
    }
}

if (-not $SkipCookieAuth) {
    & $runCookieAuthScript -BaseUrl $BaseUrl -StartupTimeoutSeconds $StartupTimeoutSeconds
    if ($LASTEXITCODE -ne 0) {
        throw "Cookie auth check failed."
    }
}

if (-not $SkipFrontendTests) {
    & $runFrontendTestsScript `
        -InstallDeps:$InstallFrontendDeps `
        -SkipUnitTests:$SkipFrontendUnitTests

    if ($LASTEXITCODE -ne 0) {
        throw "Frontend test suite failed for admin_docente."
    }
}

Write-Host "All selected admin/docente suites passed."
