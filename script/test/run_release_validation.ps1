param(
    [switch]$SkipSql,
    [switch]$SkipWeb,
    [switch]$IncludeAluno,
    [switch]$InstallBackendDeps,
    [switch]$InstallWebDeps,
    [switch]$RunSqlTruncate,
    [string]$SqlServer = "127.0.0.1",
    [string]$SqlUser = "peci_user",
    [string]$SqlDatabase = "peci_db",
    [string]$SqlPass = "",
    [string]$PsqlPath = "",
    [switch]$KeepArtifacts,
    [switch]$IncludeAiArtifacts,
    [switch]$CleanTempLogs
)

$ErrorActionPreference = "Stop"

$runAllScript = Join-Path $PSScriptRoot "run_all_tests.ps1"
$cleanScript = Join-Path $PSScriptRoot "clean_test_artifacts.ps1"

if (-not (Test-Path $runAllScript)) {
    throw "Script em falta: $runAllScript"
}

if (-not (Test-Path $cleanScript)) {
    throw "Script em falta: $cleanScript"
}

$testArgs = @{
    SkipSql = $SkipSql
    SkipWeb = $SkipWeb
    SkipAluno = (-not $IncludeAluno)
    InstallBackendDeps = $InstallBackendDeps
    InstallWebDeps = $InstallWebDeps
    RunSqlTruncate = $RunSqlTruncate
    SqlServer = $SqlServer
    SqlUser = $SqlUser
    SqlDatabase = $SqlDatabase
    SqlPass = $SqlPass
    PsqlPath = $PsqlPath
}

Write-Host "[RELEASE] A executar validacao integrada antes da limpeza..." -ForegroundColor Cyan
& $runAllScript @testArgs
$testsExitCode = $LASTEXITCODE

if ($testsExitCode -ne 0) {
    throw "Validacao integrada falhou com codigo $testsExitCode. Limpeza nao executada."
}

if ($KeepArtifacts) {
    Write-Host "[RELEASE] Artefactos mantidos por flag (-KeepArtifacts)." -ForegroundColor Yellow
    exit 0
}

Write-Host "[RELEASE] Testes concluidos. A limpar artefactos antes de publicar..." -ForegroundColor Cyan
& $cleanScript -IncludeAiArtifacts:$IncludeAiArtifacts -KeepTempLogs:(-not $CleanTempLogs)

if ($LASTEXITCODE -ne 0) {
    throw "Limpeza de artefactos falhou com codigo $LASTEXITCODE"
}

Write-Host "[RELEASE] Validacao + limpeza concluidas. Repositorio pronto para commit/push." -ForegroundColor Green