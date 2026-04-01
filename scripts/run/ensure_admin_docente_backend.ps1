[CmdletBinding()]
param(
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [int]$StartupTimeoutSeconds = 45,
    [switch]$RestartIfHealthy,
    [switch]$InstallDeps,
    [ValidateSet("local", "production")]
    [string]$CookieMode = "local"
)

$ErrorActionPreference = "Stop"

$runDir = $PSScriptRoot
$scriptsDir = Split-Path -Parent $runDir
$projectRoot = Split-Path -Parent $scriptsDir
$backendDir = Join-Path $projectRoot "backend\backend"

if (-not (Test-Path $backendDir)) {
    throw "Backend directory not found: $backendDir"
}

function Get-PythonExecutable {
    $venvPython = Join-Path $projectRoot ".venv\Scripts\python.exe"
    if (Test-Path $venvPython) {
        return $venvPython
    }

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        return $pythonCmd.Source
    }

    throw "Python executable not found. Install Python or create .venv in New_Peci_Project."
}

function Stop-ProcessOnPort {
    param([int]$Port)

    $listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if (-not $listening) {
        return
    }

    $processIds = $listening | Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($targetProcessId in $processIds) {
        try {
            Stop-Process -Id $targetProcessId -Force -ErrorAction Stop
            Write-Host "Stopped process on port $Port (PID=$targetProcessId)."
        }
        catch {
            Write-Warning ("Failed to stop PID={0} on port {1}: {2}" -f $targetProcessId, $Port, $_.Exception.Message)
        }
    }
}

function Test-Health {
    param([string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

$uri = [uri]$BaseUrl
$serverAddress = if ($uri.Host) { $uri.Host } else { "127.0.0.1" }
$port = if ($uri.Port -gt 0) { $uri.Port } else { 8000 }
$healthUrl = "$($uri.Scheme)://$serverAddress`:$port/health"

if (Test-Health -Url $healthUrl) {
    if (-not $RestartIfHealthy) {
        Write-Host "Backend is already healthy at $BaseUrl"
        exit 0
    }

    Stop-ProcessOnPort -Port $port
    Start-Sleep -Seconds 1
}

$python = Get-PythonExecutable

if ($InstallDeps) {
    Push-Location $backendDir
    try {
        & $python -m pip install -r app/requirements.txt
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install backend runtime dependencies."
        }

        & $python -m pip install -r requirements-dev.txt
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install backend dev dependencies."
        }
    }
    finally {
        Pop-Location
    }
}

$previousCookieSecure = $env:AUTH_COOKIE_SECURE
$previousCookieSameSite = $env:AUTH_COOKIE_SAMESITE
$previousCookieDomain = $env:AUTH_COOKIE_DOMAIN
$previousCookiePath = $env:AUTH_COOKIE_PATH

try {
    if ($CookieMode -eq "local") {
        # Local mode enables cookie transmission over http:// during development tests.
        $env:AUTH_COOKIE_SECURE = "false"
        $env:AUTH_COOKIE_SAMESITE = "lax"
        $env:AUTH_COOKIE_DOMAIN = ""
        $env:AUTH_COOKIE_PATH = "/"
    }
    else {
        $env:AUTH_COOKIE_SECURE = "true"
        $env:AUTH_COOKIE_SAMESITE = "none"
        if (-not $env:AUTH_COOKIE_PATH) { $env:AUTH_COOKIE_PATH = "/" }
    }

    $stdoutPath = Join-Path $env:TEMP "peci_admin_docente_backend.out.log"
    $stderrPath = Join-Path $env:TEMP "peci_admin_docente_backend.err.log"

    $uvicornParams = @("-m", "uvicorn", "app.main:app", "--host", $serverAddress, "--port", $port.ToString())
    $process = Start-Process -FilePath $python -ArgumentList $uvicornParams -WorkingDirectory $backendDir -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath

    $deadline = (Get-Date).AddSeconds($StartupTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-Health -Url $healthUrl) {
            Write-Host "Backend is healthy at $BaseUrl"
            Write-Host "PID: $($process.Id)"
            Write-Host "Logs: $stdoutPath | $stderrPath"
            exit 0
        }

        Start-Sleep -Seconds 1
    }

    throw "Backend did not become healthy within $StartupTimeoutSeconds seconds. Check logs: $stdoutPath and $stderrPath"
}
finally {
    if ($null -eq $previousCookieSecure) { Remove-Item Env:AUTH_COOKIE_SECURE -ErrorAction SilentlyContinue } else { $env:AUTH_COOKIE_SECURE = $previousCookieSecure }
    if ($null -eq $previousCookieSameSite) { Remove-Item Env:AUTH_COOKIE_SAMESITE -ErrorAction SilentlyContinue } else { $env:AUTH_COOKIE_SAMESITE = $previousCookieSameSite }
    if ($null -eq $previousCookieDomain) { Remove-Item Env:AUTH_COOKIE_DOMAIN -ErrorAction SilentlyContinue } else { $env:AUTH_COOKIE_DOMAIN = $previousCookieDomain }
    if ($null -eq $previousCookiePath) { Remove-Item Env:AUTH_COOKIE_PATH -ErrorAction SilentlyContinue } else { $env:AUTH_COOKIE_PATH = $previousCookiePath }
}
