param(
	[switch]$SkipBackendBootstrap,
	[switch]$SkipInfra,
	[switch]$SkipBootstrapData,
	[string]$BackendBaseUrl = "http://127.0.0.1:8000",
	[int]$BackendStartupTimeoutSeconds = 45
)

$ErrorActionPreference = "Stop"
$BootstrapScript = Join-Path -Path $PSScriptRoot -ChildPath "ensure_web_backend.ps1"
$TargetDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\admin"
$AdminUrl = "http://localhost:5174"

if (-not (Test-Path $BootstrapScript)) {
	throw "Script de bootstrap backend nao encontrado: $BootstrapScript"
}

if (-not $SkipBackendBootstrap) {
	Write-Host "[SISTEMA] A garantir infraestrutura e backend para operacoes persistentes..." -ForegroundColor Cyan
	& $BootstrapScript -BaseUrl $BackendBaseUrl -StartupTimeoutSeconds $BackendStartupTimeoutSeconds -SkipInfra:$SkipInfra -SkipBootstrapData:$SkipBootstrapData
}
else {
	Write-Host "[SISTEMA] Bootstrap backend ignorado (-SkipBackendBootstrap)." -ForegroundColor Yellow
}

Write-Host "[SISTEMA] A transitar contexto de execucao para: $TargetDir" -ForegroundColor Cyan
Set-Location -Path $TargetDir

Write-Host "[SISTEMA] A abrir: $AdminUrl" -ForegroundColor Cyan
Start-Process $AdminUrl | Out-Null

Write-Host "[SISTEMA] A iniciar o servidor de desenvolvimento Vue 3 (Vite) na porta 5174..." -ForegroundColor Cyan
npm run dev -- --host --port 5174 --strictPort