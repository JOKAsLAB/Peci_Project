param(
    [switch]$PubGet
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$alunoDir = Join-Path $repoRoot "aluno"

if (-not (Test-Path $alunoDir)) {
    throw "Diretorio aluno nao encontrado: $alunoDir"
}

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    throw "Comando flutter nao encontrado. Instala Flutter SDK e adiciona ao PATH."
}

Push-Location $alunoDir
try {
    if ($PubGet) {
        Write-Host "[TEST][FLUTTER] A executar flutter pub get..." -ForegroundColor Cyan
        flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw "Falha no flutter pub get"
        }
    }

    Write-Host "[TEST][FLUTTER] A executar widget tests..." -ForegroundColor Cyan
    flutter test test/widget_test.dart
    if ($LASTEXITCODE -ne 0) {
        throw "Falha nos widget tests (codigo $LASTEXITCODE)."
    }

    Write-Host "[TEST][FLUTTER] Widget tests concluidos com sucesso." -ForegroundColor Green
}
finally {
    Pop-Location
}
