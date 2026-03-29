param(
	[switch]$SkipBackendBootstrap,
	[switch]$SkipInfra,
	[switch]$SkipBootstrapData,
	[switch]$RestartBackendIfHealthy,
	[switch]$RestartFrontendIfRunning,
	[string]$BackendBaseUrl = "http://127.0.0.1:8000",
	[int]$BackendStartupTimeoutSeconds = 45
)

$ErrorActionPreference = "Stop"
$BootstrapScript = Join-Path -Path $PSScriptRoot -ChildPath "ensure_web_backend.ps1"
$TargetDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\admin"
$AdminUrl = "http://localhost:5174"
$AdminPort = 5174

function Get-ListeningProcess {
	param([int]$Port)

	$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
	if (-not $listener) {
		return $null
	}

	return Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
}

if (-not (Test-Path $BootstrapScript)) {
	throw "Script de bootstrap backend nao encontrado: $BootstrapScript"
}

if (-not $SkipBackendBootstrap) {
	Write-Host "[SISTEMA] A garantir infraestrutura e backend para operacoes persistentes..." -ForegroundColor Cyan
	& $BootstrapScript -BaseUrl $BackendBaseUrl -StartupTimeoutSeconds $BackendStartupTimeoutSeconds -SkipInfra:$SkipInfra -SkipBootstrapData:$SkipBootstrapData -RestartHealthyBackend:$RestartBackendIfHealthy
}
else {
	Write-Host "[SISTEMA] Bootstrap backend ignorado (-SkipBackendBootstrap)." -ForegroundColor Yellow
}

Write-Host "[SISTEMA] A transitar contexto de execucao para: $TargetDir" -ForegroundColor Cyan
Set-Location -Path $TargetDir

$existingFrontendProc = Get-ListeningProcess -Port $AdminPort
if ($existingFrontendProc) {
	if ($RestartFrontendIfRunning) {
		Write-Host "[SISTEMA] Porta $AdminPort ocupada por PID $($existingFrontendProc.Id) ($($existingFrontendProc.ProcessName)). A reiniciar frontend..." -ForegroundColor Yellow
		Stop-Process -Id $existingFrontendProc.Id -Force
		Start-Sleep -Milliseconds 400
	}
	elseif ($existingFrontendProc.ProcessName -ieq "node") {
		Write-Host "[SISTEMA] Frontend admin ja esta ativo na porta $AdminPort (PID $($existingFrontendProc.Id))." -ForegroundColor Green
		Write-Host "[SISTEMA] Use -RestartFrontendIfRunning para forcar restart quando necessario." -ForegroundColor DarkYellow
		Write-Host "[SISTEMA] A abrir: $AdminUrl" -ForegroundColor Cyan
		Start-Process $AdminUrl | Out-Null
		exit 0
	}
	else {
		throw "Porta $AdminPort ja ocupada por '$($existingFrontendProc.ProcessName)' (PID $($existingFrontendProc.Id)). Fecha esse processo ou usa outra porta."
	}
}

Write-Host "[SISTEMA] A abrir: $AdminUrl" -ForegroundColor Cyan
Start-Process $AdminUrl | Out-Null

Write-Host "[SISTEMA] A iniciar o servidor de desenvolvimento Vue 3 (Vite) na porta 5174..." -ForegroundColor Cyan
npm run dev -- --host --port 5174 --strictPort