param(
    [switch]$SkipSql,
    [switch]$SkipWeb,
    [switch]$SkipWebE2E,
    [switch]$SkipAluno,
    [switch]$InstallBackendDeps,
    [switch]$InstallWebDeps,
    [switch]$RunSqlTruncate,
    [string]$SqlServer = "127.0.0.1",
    [string]$SqlUser = "peci_user",
    [string]$SqlDatabase = "peci_db",
    [string]$SqlPass = "",
    [string]$PsqlPath = "",
    [string]$WebE2EBackendBaseUrl = "http://127.0.0.1:8012"
)

$ErrorActionPreference = "Stop"

$backendSmokeScript = Join-Path $PSScriptRoot "run_backend_smoke.ps1"
$webStoreScript = Join-Path $PSScriptRoot "run_web_store_tests.ps1"
$webE2EScript = Join-Path $PSScriptRoot "run_web_e2e_tests.ps1"
$sqlScript = Join-Path $PSScriptRoot "run_database_sql_tests.ps1"
$alunoWidgetScript = Join-Path $PSScriptRoot "run_aluno_widget_tests.ps1"

if (-not (Test-Path $backendSmokeScript)) { throw "Script em falta: $backendSmokeScript" }
if (-not (Test-Path $webStoreScript)) { throw "Script em falta: $webStoreScript" }
if (-not (Test-Path $webE2EScript)) { throw "Script em falta: $webE2EScript" }
if (-not (Test-Path $sqlScript)) { throw "Script em falta: $sqlScript" }
if (-not (Test-Path $alunoWidgetScript)) { throw "Script em falta: $alunoWidgetScript" }

Write-Host "[TEST][ALL] 1/5 Backend smoke..." -ForegroundColor Cyan
& $backendSmokeScript -InstallDeps:$InstallBackendDeps
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not $SkipWeb) {
    Write-Host "[TEST][ALL] 2/5 Web store tests (Admin + Professor)..." -ForegroundColor Cyan
    & $webStoreScript -InstallDeps:$InstallWebDeps
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    if (-not $SkipWebE2E) {
        Write-Host "[TEST][ALL] 3/5 Web E2E tests (Admin + Professor)..." -ForegroundColor Cyan
        & $webE2EScript -InstallDeps:$InstallWebDeps -BackendBaseUrl $WebE2EBackendBaseUrl
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
    }
    else {
        Write-Host "[TEST][ALL] 3/5 Web E2E tests ignorados (-SkipWebE2E)." -ForegroundColor Yellow
    }
}
else {
    Write-Host "[TEST][ALL] 2/5 Web store tests ignorados (-SkipWeb)." -ForegroundColor Yellow
    Write-Host "[TEST][ALL] 3/5 Web E2E tests ignorados (-SkipWeb)." -ForegroundColor Yellow
}

if (-not $SkipSql) {
    Write-Host "[TEST][ALL] 4/5 SQL tests..." -ForegroundColor Cyan
    & $sqlScript -SqlServer $SqlServer -User $SqlUser -Database $SqlDatabase -DbPass $SqlPass -PsqlPath $PsqlPath -RunTruncate:$RunSqlTruncate
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
else {
    Write-Host "[TEST][ALL] 4/5 SQL tests ignorados (-SkipSql)." -ForegroundColor Yellow
}

if (-not $SkipAluno) {
    Write-Host "[TEST][ALL] 5/5 Flutter widget tests..." -ForegroundColor Cyan
    & $alunoWidgetScript
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
else {
    Write-Host "[TEST][ALL] 5/5 Flutter widget tests ignorados (-SkipAluno)." -ForegroundColor Yellow
}

Write-Host "[TEST][ALL] Suite completa concluida com sucesso." -ForegroundColor Green
