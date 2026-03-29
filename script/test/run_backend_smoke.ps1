param(
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [int]$StartupTimeoutSeconds = 35,
    [switch]$InstallDeps,
    [string]$AdminEmail = "",
    [string]$AdminPassword = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$backendDir = Join-Path $repoRoot "backend/backend"
$pythonExe = Join-Path $repoRoot ".venv/Scripts/python.exe"

if (-not (Test-Path $pythonExe)) {
    throw "Python virtual environment not found at $pythonExe"
}

if (-not (Test-Path $backendDir)) {
    throw "Backend directory not found at $backendDir"
}

$serverProc = $null

function Get-FreeTcpPort {
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    try {
        $listener.Start()
        return $listener.LocalEndpoint.Port
    }
    finally {
        $listener.Stop()
    }
}

function Resolve-BaseUrl {
    param([string]$Url)

    try {
        return [System.Uri]$Url
    }
    catch {
        throw "BaseUrl invalido: $Url"
    }
}

function Test-PortBusy {
    param([int]$Port)

    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    return $null -ne $listener
}

Push-Location $backendDir
try {
    if ($InstallDeps) {
        & $pythonExe -m pip install -r app/requirements.txt
        if ($LASTEXITCODE -ne 0) { throw "Failed to install app requirements" }

        & $pythonExe -m pip install -r requirements-dev.txt
        if ($LASTEXITCODE -ne 0) { throw "Failed to install dev requirements" }
    }

    $baseUri = Resolve-BaseUrl -Url $BaseUrl
    if ($baseUri.Host -ne "127.0.0.1" -and $baseUri.Host -ne "localhost") {
        throw "run_backend_smoke.ps1 exige BaseUrl local (localhost/127.0.0.1). Recebido: $BaseUrl"
    }

    $effectivePort = $baseUri.Port
    if (Test-PortBusy -Port $effectivePort) {
        $fallbackPort = Get-FreeTcpPort
        Write-Warning "Porta $effectivePort ocupada. A usar porta livre alternativa $fallbackPort para smoke tests."
        $effectivePort = $fallbackPort
    }

    $effectiveBaseUrl = "http://127.0.0.1:$effectivePort"
    $env:SMOKE_BASE_URL = $effectiveBaseUrl

    if ($AdminEmail -and $AdminPassword) {
        $env:SMOKE_ADMIN_EMAIL = $AdminEmail
        $env:SMOKE_ADMIN_PASSWORD = $AdminPassword
    }

    $serverProc = Start-Process -FilePath $pythonExe -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "$effectivePort") -PassThru -WindowStyle Hidden

    $healthUrl = "$effectiveBaseUrl/health"
    $deadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
    $ready = $false

    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 900

        if ($serverProc.HasExited) {
            break
        }

        try {
            $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 3
            if ($response.StatusCode -eq 200) {
                $ready = $true
                break
            }
        }
        catch {
            # Keep waiting until timeout.
        }
    }

    if (-not $ready) {
        Write-Host "API did not become healthy within $StartupTimeoutSeconds seconds. Running smoke tests anyway (tests may skip)."
    }

    & $pythonExe -m pytest tests/smoke -q
    $testExitCode = $LASTEXITCODE

    exit $testExitCode
}
finally {
    if ($serverProc -and -not $serverProc.HasExited) {
        Stop-Process -Id $serverProc.Id -Force
    }
    Pop-Location
}
