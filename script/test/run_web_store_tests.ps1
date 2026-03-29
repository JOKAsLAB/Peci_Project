param(
    [switch]$InstallDeps
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$adminDir = Join-Path $repoRoot "admin"
$professorDir = Join-Path $repoRoot "professor"

if (-not (Test-Path $adminDir)) { throw "Diretorio admin nao encontrado: $adminDir" }
if (-not (Test-Path $professorDir)) { throw "Diretorio professor nao encontrado: $professorDir" }

function Invoke-WebStoreTests {
    param(
        [string]$ProjectDir,
        [string]$Label
    )

    Push-Location $ProjectDir
    try {
        if ($InstallDeps) {
            Write-Host "[TEST][WEB][$Label] A instalar dependencias npm..." -ForegroundColor Cyan
            npm install
            if ($LASTEXITCODE -ne 0) {
                throw "Falha no npm install para $Label"
            }
        }

        Write-Host "[TEST][WEB][$Label] A executar Vitest (stores)..." -ForegroundColor Cyan
        npm run test:run
        if ($LASTEXITCODE -ne 0) {
            throw "Falha nos testes frontend de $Label"
        }
    }
    finally {
        Pop-Location
    }
}

Invoke-WebStoreTests -ProjectDir $adminDir -Label "admin"
Invoke-WebStoreTests -ProjectDir $professorDir -Label "professor"

Write-Host "[TEST][WEB] Suite frontend (Admin + Professor) concluida com sucesso." -ForegroundColor Green
