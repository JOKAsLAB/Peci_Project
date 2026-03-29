param(
    [switch]$InstallDeps,
    [switch]$Headed,
    [string]$BackendBaseUrl = "http://127.0.0.1:8010",
    [string]$AdminBaseUrl = "http://127.0.0.1:5174",
    [string]$ProfessorBaseUrl = "http://127.0.0.1:5173",
    [int]$StartupTimeoutSeconds = 70,
    [string]$AdminEmail = "admin@ua.pt",
    [string]$AdminPassword = "admin123"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ensureBackendScript = Join-Path $repoRoot "script/run/ensure_web_backend.ps1"
$adminDir = Join-Path $repoRoot "admin"
$professorDir = Join-Path $repoRoot "professor"
$e2eDir = Join-Path $PSScriptRoot "e2e"

if (-not (Test-Path $ensureBackendScript)) { throw "Script em falta: $ensureBackendScript" }
if (-not (Test-Path $adminDir)) { throw "Diretorio em falta: $adminDir" }
if (-not (Test-Path $professorDir)) { throw "Diretorio em falta: $professorDir" }
if (-not (Test-Path $e2eDir)) { throw "Diretorio E2E em falta: $e2eDir" }

function Resolve-BaseUri {
    param([string]$Url)

    try {
        return [System.Uri]$Url
    }
    catch {
        throw "URL invalida: $Url"
    }
}

function Assert-LocalHost {
    param([System.Uri]$Uri)

    if ($Uri.Host -ne "127.0.0.1" -and $Uri.Host -ne "localhost") {
        throw "Este runner exige hosts locais (127.0.0.1/localhost). Recebido: $($Uri.AbsoluteUri)"
    }
}

function Test-HttpReady {
    param([string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return $response.StatusCode -ge 200 -and $response.StatusCode -lt 500
    }
    catch {
        return $false
    }
}

function Wait-HttpReady {
    param(
        [string]$Url,
        [int]$TimeoutSeconds,
        [string]$Label
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-HttpReady -Url $Url) {
            return
        }
        Start-Sleep -Milliseconds 800
    }

    throw "Timeout a aguardar $Label em $Url"
}

function Get-ListenerProcess {
    param([int]$Port)

    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $listener) {
        return $null
    }

    return Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
}

function Ensure-WebDevServer {
    param(
        [string]$ProjectDir,
        [int]$Port,
        [string]$Label
    )

    $existingProc = Get-ListenerProcess -Port $Port
    if ($existingProc) {
        if ($existingProc.ProcessName -ine "node") {
            throw "Porta $Port ocupada por processo nao suportado ($($existingProc.ProcessName), PID $($existingProc.Id))."
        }

        Write-Host "[TEST][E2E][$Label] Reiniciar servidor existente na porta $Port (PID $($existingProc.Id)) para execucao deterministica." -ForegroundColor Yellow
        Stop-Process -Id $existingProc.Id -Force
        Start-Sleep -Milliseconds 500
    }

    Write-Host "[TEST][E2E][$Label] Arrancar Vite na porta $Port..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath "npm.cmd" -ArgumentList @("run", "dev", "--", "--host", "127.0.0.1", "--port", "$Port", "--strictPort") -WorkingDirectory $ProjectDir -PassThru -WindowStyle Hidden
    Start-Sleep -Milliseconds 800

    if ($proc.HasExited) {
        throw "Falha ao arrancar servidor Vite de $Label na porta $Port."
    }

    return $proc
}

$adminUri = Resolve-BaseUri -Url $AdminBaseUrl
$professorUri = Resolve-BaseUri -Url $ProfessorBaseUrl
$backendUri = Resolve-BaseUri -Url $BackendBaseUrl

Assert-LocalHost -Uri $adminUri
Assert-LocalHost -Uri $professorUri
Assert-LocalHost -Uri $backendUri

$startedServerProcesses = @()
$enteredE2EDirectory = $false
$originalViteApiBaseUrl = $env:VITE_API_BASE_URL

try {
    Write-Host "[TEST][E2E] Garantir backend ativo via ensure_web_backend..." -ForegroundColor Cyan
    & $ensureBackendScript -BaseUrl $BackendBaseUrl -RestartHealthyBackend
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao preparar backend para E2E."
    }

    $env:VITE_API_BASE_URL = $BackendBaseUrl

    $adminServerProc = Ensure-WebDevServer -ProjectDir $adminDir -Port $adminUri.Port -Label "admin"
    if ($adminServerProc) {
        $startedServerProcesses += $adminServerProc
    }

    $professorServerProc = Ensure-WebDevServer -ProjectDir $professorDir -Port $professorUri.Port -Label "professor"
    if ($professorServerProc) {
        $startedServerProcesses += $professorServerProc
    }

    Wait-HttpReady -Url $AdminBaseUrl -TimeoutSeconds $StartupTimeoutSeconds -Label "Admin Web"
    Wait-HttpReady -Url $ProfessorBaseUrl -TimeoutSeconds $StartupTimeoutSeconds -Label "Professor Web"

    Push-Location $e2eDir
    $enteredE2EDirectory = $true

    if ($InstallDeps) {
        Write-Host "[TEST][E2E] Instalar dependencias Playwright..." -ForegroundColor Cyan
        npm install
        if ($LASTEXITCODE -ne 0) {
            throw "Falha no npm install (E2E)."
        }
    }

    Write-Host "[TEST][E2E] Garantir browser Chromium do Playwright..." -ForegroundColor Cyan
    npx playwright install chromium
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao instalar browser Chromium para Playwright."
    }

    $env:ADMIN_BASE_URL = $AdminBaseUrl
    $env:PROFESSOR_BASE_URL = $ProfessorBaseUrl
    $env:E2E_ADMIN_EMAIL = $AdminEmail
    $env:E2E_ADMIN_PASSWORD = $AdminPassword
    $env:PW_HEADLESS = if ($Headed) { "false" } else { "true" }

    Write-Host "[TEST][E2E] Executar browser tests Admin+Professor..." -ForegroundColor Cyan
    npx playwright test
    if ($LASTEXITCODE -ne 0) {
        throw "Falha nos testes E2E web (codigo $LASTEXITCODE)."
    }

    Write-Host "[TEST][E2E] Suite E2E web concluida com sucesso." -ForegroundColor Green
}
finally {
    if ($enteredE2EDirectory) {
        Pop-Location
    }

    $env:VITE_API_BASE_URL = $originalViteApiBaseUrl

    foreach ($proc in $startedServerProcesses) {
        if ($proc -and -not $proc.HasExited) {
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}