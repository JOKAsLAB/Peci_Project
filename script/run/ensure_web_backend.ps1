param(
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [int]$StartupTimeoutSeconds = 45,
    [switch]$SkipInfra,
    [switch]$SkipBootstrapData
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$infraDir = Join-Path $repoRoot "infrastructure"
$infraEnv = Join-Path $infraDir ".env"
$infraEnvExample = Join-Path $infraDir ".env.example"
$backendDir = Join-Path $repoRoot "backend/backend"
$backendEnv = Join-Path $backendDir "app/.env"
$backendRequirements = Join-Path $backendDir "app/requirements.txt"
$backendBootstrapScript = Join-Path $repoRoot "script/backend/bootstrap_local_stack.py"
$healthUrl = "$BaseUrl/health"

function Test-ApiHealthy {
    param([string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

function Read-EnvFile {
    param([string]$Path)

    $result = @{}
    if (-not (Test-Path $Path)) {
        return $result
    }

    foreach ($line in Get-Content -Path $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed) { continue }
        if ($trimmed.StartsWith("#")) { continue }

        $idx = $trimmed.IndexOf("=")
        if ($idx -lt 1) { continue }

        $key = $trimmed.Substring(0, $idx).Trim()
        $value = $trimmed.Substring($idx + 1).Trim()
        $result[$key] = $value
    }

    return $result
}

function Ensure-Infrastructure {
    param([string]$Directory)

    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Warning "Docker nao encontrado no PATH. A saltar bootstrap de infraestrutura via compose."
        return
    }

    if (-not (Test-Path $Directory)) {
        throw "Diretorio de infraestrutura nao encontrado em: $Directory"
    }

    if (-not (Test-Path $infraEnv) -and (Test-Path $infraEnvExample)) {
        Copy-Item -Path $infraEnvExample -Destination $infraEnv
        Write-Host "[SISTEMA] infrastructure/.env criado a partir de .env.example" -ForegroundColor Yellow
    }

    Write-Host "[SISTEMA] A garantir PostgreSQL e ChromaDB via docker compose..." -ForegroundColor Cyan
    Push-Location $Directory
    try {
        docker compose up -d postgres chromadb
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Falha ao executar docker compose para infraestrutura. A continuar para tentar backend com stack ja existente."
        }
    }
    finally {
        Pop-Location
    }
}

function Ensure-BackendEnv {
    if (Test-Path $backendEnv) {
        return
    }

    $infraConfig = @{}
    if (Test-Path $infraEnv) {
        $infraConfig = Read-EnvFile -Path $infraEnv
    }
    elseif (Test-Path $infraEnvExample) {
        $infraConfig = Read-EnvFile -Path $infraEnvExample
    }

    $dbUser = if ($infraConfig.ContainsKey("POSTGRES_USER")) { $infraConfig["POSTGRES_USER"] } else { "peci" }
    $dbPassword = if ($infraConfig.ContainsKey("POSTGRES_PASSWORD")) { $infraConfig["POSTGRES_PASSWORD"] } else { "peci" }
    $dbPort = if ($infraConfig.ContainsKey("POSTGRES_PORT")) { $infraConfig["POSTGRES_PORT"] } else { "5432" }
    $dbName = if ($infraConfig.ContainsKey("POSTGRES_DB")) { $infraConfig["POSTGRES_DB"] } else { "peci_db" }
    $secret = "local-dev-" + [Guid]::NewGuid().ToString("N") + [Guid]::NewGuid().ToString("N")

    $content = @(
        "DB_USER=$dbUser",
        "DB_PASSWORD=$dbPassword",
        "DB_HOST=127.0.0.1",
        "DB_PORT=$dbPort",
        "DB_NAME=$dbName",
        "",
        "SECRET_KEY=$secret",
        "ALGORITHM=HS256",
        "ACCESS_TOKEN_EXPIRE_MINUTES=60"
    ) -join "`r`n"

    Set-Content -Path $backendEnv -Value $content
    Write-Host "[SISTEMA] backend/backend/app/.env criado automaticamente para ambiente local." -ForegroundColor Yellow
}

function Resolve-PythonExecutable {
    param([string]$RepositoryRoot)

    $venvPython = Join-Path $RepositoryRoot ".venv/Scripts/python.exe"
    if (Test-Path $venvPython) {
        return $venvPython
    }

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        return $pythonCmd.Source
    }

    throw "Python nao encontrado. Cria/ativa um ambiente Python antes de iniciar o backend."
}

function Ensure-BackendPython {
    param([string]$RepositoryRoot)

    $venvPython = Join-Path $RepositoryRoot ".venv/Scripts/python.exe"
    if (Test-Path $venvPython) {
        return $venvPython
    }

    $pythonCmd = Resolve-PythonExecutable -RepositoryRoot $RepositoryRoot
    Write-Host "[SISTEMA] A criar ambiente virtual local em .venv..." -ForegroundColor Cyan
    & $pythonCmd -m venv (Join-Path $RepositoryRoot ".venv")
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao criar ambiente virtual Python em .venv"
    }

    if (-not (Test-Path $venvPython)) {
        throw "Ambiente virtual foi criado, mas python.exe nao foi encontrado em .venv/Scripts"
    }

    return $venvPython
}

function Ensure-BackendDependencies {
    param(
        [string]$PythonExe,
        [string]$RequirementsFile,
        [string]$WorkingDirectory
    )

    if (-not (Test-Path $RequirementsFile)) {
        throw "Nao foi encontrado requirements do backend: $RequirementsFile"
    }

    $checkImports = "import fastapi, sqlalchemy, asyncpg, pydantic_settings, jose, passlib, email_validator"
    & $PythonExe -c $checkImports 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        return
    }

    Write-Host "[SISTEMA] A instalar dependencias Python do backend..." -ForegroundColor Cyan
    Push-Location $WorkingDirectory
    try {
        & $PythonExe -m pip install -r app/requirements.txt
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao instalar dependencias em app/requirements.txt"
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-BackendBootstrap {
    param(
        [string]$PythonExe,
        [string]$WorkingDirectory,
        [string]$BootstrapScript,
        [switch]$SkipData
    )

    if ($SkipData) {
        Write-Host "[SISTEMA] Bootstrap de schema/dados ignorado por flag (-SkipBootstrapData)." -ForegroundColor Yellow
        return
    }

    if (-not (Test-Path $BootstrapScript)) {
        Write-Warning "Script de bootstrap de dados nao encontrado: $BootstrapScript"
        return
    }

    Push-Location $WorkingDirectory
    try {
        $attempts = 8
        for ($attempt = 1; $attempt -le $attempts; $attempt++) {
            & $PythonExe $BootstrapScript
            if ($LASTEXITCODE -eq 0) {
                return
            }

            if ($attempt -lt $attempts) {
                Write-Host "[SISTEMA] Bootstrap local falhou (tentativa $attempt/$attempts). A repetir..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }

        throw "Falha no bootstrap local de schema/conta admin apos varias tentativas. Confirma PostgreSQL ativo (Docker Compose ou instalacao local) e credenciais no backend/backend/app/.env."
    }
    finally {
        Pop-Location
    }
}

if (Test-ApiHealthy -Url $healthUrl) {
    Write-Host "[SISTEMA] Backend ja esta saudavel em $BaseUrl" -ForegroundColor Green
    exit 0
}

if (-not $SkipInfra) {
    Ensure-Infrastructure -Directory $infraDir

    if (Test-ApiHealthy -Url $healthUrl) {
        Write-Host "[SISTEMA] Backend ja estava ativo apos garantir a infraestrutura." -ForegroundColor Green
        exit 0
    }
}

if (-not (Test-Path $backendDir)) {
    throw "Diretorio do backend nao encontrado em: $backendDir"
}

Ensure-BackendEnv
$pythonExe = Ensure-BackendPython -RepositoryRoot $repoRoot
Ensure-BackendDependencies -PythonExe $pythonExe -RequirementsFile $backendRequirements -WorkingDirectory $backendDir
Invoke-BackendBootstrap -PythonExe $pythonExe -WorkingDirectory $backendDir -BootstrapScript $backendBootstrapScript -SkipData:$SkipBootstrapData

$outLog = Join-Path $env:TEMP "peci_backend.out.log"
$errLog = Join-Path $env:TEMP "peci_backend.err.log"

Write-Host "[SISTEMA] A iniciar backend FastAPI em background ($BaseUrl)..." -ForegroundColor Cyan
$startProcessArgs = @{
    FilePath = $pythonExe
    ArgumentList = @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000", "--reload")
    WorkingDirectory = $backendDir
    PassThru = $true
    WindowStyle = "Hidden"
    RedirectStandardOutput = $outLog
    RedirectStandardError = $errLog
}
$backendProc = Start-Process @startProcessArgs

$deadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 900

    if ($backendProc.HasExited) {
        $errorTail = ""
        if (Test-Path $errLog) {
            $errorTail = (Get-Content -Path $errLog -Tail 30 -ErrorAction SilentlyContinue) -join [Environment]::NewLine
        }
        throw "Backend terminou prematuramente (PID $($backendProc.Id)).`n$errorTail"
    }

    if (Test-ApiHealthy -Url $healthUrl) {
        Write-Host "[SISTEMA] Backend pronto em $BaseUrl (PID $($backendProc.Id))." -ForegroundColor Green
        exit 0
    }
}

throw "Backend nao ficou saudavel em $StartupTimeoutSeconds segundos. Consulta logs: $outLog e $errLog"