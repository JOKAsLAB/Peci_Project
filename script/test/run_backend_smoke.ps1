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

Push-Location $backendDir
try {
    if ($InstallDeps) {
        & $pythonExe -m pip install -r app/requirements.txt
        if ($LASTEXITCODE -ne 0) { throw "Failed to install app requirements" }

        & $pythonExe -m pip install -r requirements-dev.txt
        if ($LASTEXITCODE -ne 0) { throw "Failed to install dev requirements" }
    }

    $env:SMOKE_BASE_URL = $BaseUrl

    if ($AdminEmail -and $AdminPassword) {
        $env:SMOKE_ADMIN_EMAIL = $AdminEmail
        $env:SMOKE_ADMIN_PASSWORD = $AdminPassword
    }

    $serverProc = Start-Process -FilePath $pythonExe -ArgumentList @("-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000") -PassThru -WindowStyle Hidden

    $healthUrl = "$BaseUrl/health"
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
