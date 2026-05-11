[CmdletBinding()]
param(
    [string]$Device = ""
)

$ErrorActionPreference = "Stop"

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    throw "Comando flutter nao encontrado. Instala Flutter SDK e adiciona ao PATH."
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$alunoDir = Join-Path $projectRoot "aluno"
if (-not (Test-Path $alunoDir)) {
    throw "Diretorio aluno nao encontrado: $alunoDir"
}

Push-Location $alunoDir
try {
    Write-Host "[ALUNO] A executar flutter pub get..." -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "Falha no flutter pub get"
    }

    if ($Device -ne "") {
        Write-Host "[ALUNO] A executar flutter run no dispositivo '$Device'..." -ForegroundColor Cyan
        flutter run -d $Device
    } else {
        Write-Host "[ALUNO] A executar flutter run no dispositivo disponivel..." -ForegroundColor Cyan
        flutter run
    }

    if ($LASTEXITCODE -ne 0) {
        throw "Falha no flutter run (codigo $LASTEXITCODE). Verifica o output acima para diagnostico."
    }
}
finally {
    Pop-Location
}
