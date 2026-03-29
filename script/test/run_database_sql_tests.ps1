param(
    [string]$SqlServer = "127.0.0.1",
    [string]$User = "peci_user",
    [string]$Database = "peci_db",
    [string]$DbPass = "",
    [string]$PsqlPath = "",
    [switch]$RunTruncate
)

$ErrorActionPreference = "Stop"

function Resolve-PsqlExecutable {
    param([string]$UserProvidedPath)

    if ($UserProvidedPath) {
        if (Test-Path $UserProvidedPath) {
            return (Resolve-Path $UserProvidedPath).Path
        }
        throw "PsqlPath invalido: $UserProvidedPath"
    }

    $psqlCommand = Get-Command psql -ErrorAction SilentlyContinue
    if ($psqlCommand) {
        return $psqlCommand.Source
    }

    $candidates = Get-ChildItem "C:/Program Files/PostgreSQL/*/bin/psql.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending

    if ($candidates -and $candidates.Count -gt 0) {
        return $candidates[0].FullName
    }

    throw "Nao foi possivel localizar psql. Instala PostgreSQL CLI ou passa -PsqlPath."
}

$sqlDir = Join-Path $PSScriptRoot "sql"
if (-not (Test-Path $sqlDir)) {
    throw "Diretorio SQL de testes nao encontrado: $sqlDir"
}

$psqlExe = Resolve-PsqlExecutable -UserProvidedPath $PsqlPath
$filesToRun = @("test_inserts.sql", "test_admin_professor_integrity.sql", "useful_selects.sql")
if ($RunTruncate) {
    $filesToRun += "test_truncate.sql"
}

$originalPassword = $env:PGPASSWORD
if ($DbPass) {
    $env:PGPASSWORD = $DbPass
}

try {
    foreach ($fileName in $filesToRun) {
        $filePath = Join-Path $sqlDir $fileName
        if (-not (Test-Path $filePath)) {
            throw "Ficheiro SQL em falta: $filePath"
        }

        Write-Host "[TEST][SQL] A executar $fileName..." -ForegroundColor Cyan
        & $psqlExe -h $SqlServer -U $User -d $Database -v "ON_ERROR_STOP=1" -P "pager=off" -f $filePath
        if ($LASTEXITCODE -ne 0) {
            throw "Execucao falhou para $fileName (codigo $LASTEXITCODE)."
        }
    }

    if (-not $RunTruncate) {
        Write-Host "[TEST][SQL] test_truncate.sql nao foi executado (usa -RunTruncate se quiseres limpar dados)." -ForegroundColor Yellow
    }

    Write-Host "[TEST][SQL] Suite SQL concluida com sucesso." -ForegroundColor Green
}
finally {
    if ($DbPass) {
        $env:PGPASSWORD = $originalPassword
    }
}
