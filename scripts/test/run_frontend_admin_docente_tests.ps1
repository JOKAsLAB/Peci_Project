[CmdletBinding()]
param(
    [switch]$InstallDeps,
    [switch]$SkipUnitTests
)

$ErrorActionPreference = "Stop"

$testDir = $PSScriptRoot
$scriptsDir = Split-Path -Parent $testDir
$projectRoot = Split-Path -Parent $scriptsDir
$frontendDir = Join-Path $projectRoot "admin_docente"

if (-not (Test-Path $frontendDir)) {
    throw "Frontend directory not found: $frontendDir"
}

Push-Location $frontendDir
try {
    if ($InstallDeps) {
        npm install
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed in admin_docente"
        }
    }

    npm run check
    if ($LASTEXITCODE -ne 0) {
        throw "Typecheck failed (npm run check)."
    }

    if (-not $SkipUnitTests) {
        npm run test:run
        if ($LASTEXITCODE -ne 0) {
            throw "Unit tests failed (npm run test:run)."
        }
    }

    npm run build
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed (npm run build)."
    }
}
finally {
    Pop-Location
}

Write-Host "Frontend admin_docente tests completed successfully."
