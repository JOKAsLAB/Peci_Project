param(
    [switch]$SkipSql,
    [switch]$SkipWeb,
    [switch]$SkipAluno,
    [switch]$InstallBackendDeps,
    [switch]$InstallWebDeps,
    [switch]$RunSqlTruncate,
    [string]$SqlServer = "127.0.0.1",
    [string]$SqlUser = "peci_user",
    [string]$SqlDatabase = "peci_db",
    [string]$SqlPass = "",
    [string]$PsqlPath = ""
)

$ErrorActionPreference = "Stop"

$backendSmokeScript = Join-Path $PSScriptRoot "run_backend_smoke.ps1"
$webStoreScript = Join-Path $PSScriptRoot "run_web_store_tests.ps1"
$sqlScript = Join-Path $PSScriptRoot "run_database_sql_tests.ps1"
$alunoWidgetScript = Join-Path $PSScriptRoot "run_aluno_widget_tests.ps1"

if (-not (Test-Path $backendSmokeScript)) { throw "Script em falta: $backendSmokeScript" }
if (-not (Test-Path $webStoreScript)) { throw "Script em falta: $webStoreScript" }
if (-not (Test-Path $sqlScript)) { throw "Script em falta: $sqlScript" }
if (-not (Test-Path $alunoWidgetScript)) { throw "Script em falta: $alunoWidgetScript" }

Write-Host "[TEST][ALL] 1/4 Backend smoke..." -ForegroundColor Cyan
& $backendSmokeScript -InstallDeps:$InstallBackendDeps
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not $SkipWeb) {
    Write-Host "[TEST][ALL] 2/4 Web store tests (Admin + Professor)..." -ForegroundColor Cyan
    & $webStoreScript -InstallDeps:$InstallWebDeps
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
else {
    Write-Host "[TEST][ALL] 2/4 Web store tests ignorados (-SkipWeb)." -ForegroundColor Yellow
}

if (-not $SkipSql) {
    Write-Host "[TEST][ALL] 3/4 SQL tests..." -ForegroundColor Cyan
    & $sqlScript -SqlServer $SqlServer -User $SqlUser -Database $SqlDatabase -DbPass $SqlPass -PsqlPath $PsqlPath -RunTruncate:$RunSqlTruncate
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
else {
    Write-Host "[TEST][ALL] 3/4 SQL tests ignorados (-SkipSql)." -ForegroundColor Yellow
}

if (-not $SkipAluno) {
    Write-Host "[TEST][ALL] 4/4 Flutter widget tests..." -ForegroundColor Cyan
    & $alunoWidgetScript
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}
else {
    Write-Host "[TEST][ALL] 4/4 Flutter widget tests ignorados (-SkipAluno)." -ForegroundColor Yellow
}

Write-Host "[TEST][ALL] Suite completa concluida com sucesso." -ForegroundColor Green
