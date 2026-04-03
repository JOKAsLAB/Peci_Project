[CmdletBinding()]
param(
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [int]$StartupTimeoutSeconds = 45,
    [switch]$InstallBackendDeps,
    [switch]$InstallFrontendDeps,
    [switch]$SkipBackendSmoke,
    [switch]$SkipCookieAuth,
    [switch]$SkipFrontendTests,
    [switch]$SkipFrontendUnitTests,
    [switch]$SkipAluno,
    [switch]$AlunoPubGet
)

$ErrorActionPreference = "Stop"

$testDir = $PSScriptRoot
$runAdminDocenteSuite = Join-Path $testDir "run_all_admin_docente_tests.ps1"
$runAlunoWidgetTests = Join-Path $testDir "run_aluno_widget_tests.ps1"

& $runAdminDocenteSuite `
    -BaseUrl $BaseUrl `
    -StartupTimeoutSeconds $StartupTimeoutSeconds `
    -InstallBackendDeps:$InstallBackendDeps `
    -InstallFrontendDeps:$InstallFrontendDeps `
    -SkipBackendSmoke:$SkipBackendSmoke `
    -SkipCookieAuth:$SkipCookieAuth `
    -SkipFrontendTests:$SkipFrontendTests `
    -SkipFrontendUnitTests:$SkipFrontendUnitTests

if ($LASTEXITCODE -ne 0) {
    throw "Admin/docente suite failed."
}

if (-not $SkipAluno) {
    & $runAlunoWidgetTests -PubGet:$AlunoPubGet
    if ($LASTEXITCODE -ne 0) {
        throw "Aluno widget tests failed."
    }
}

Write-Host "All selected suites passed (admin/docente + optional aluno)."
