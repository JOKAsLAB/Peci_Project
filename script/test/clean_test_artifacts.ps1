param(
    [switch]$IncludeAiArtifacts,
    [switch]$KeepTempLogs
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Remove-TargetIfExists {
    param(
        [string]$AbsolutePath,
        [ref]$RemovedCount,
        [ref]$SkippedCount,
        [switch]$IgnoreErrors
    )

    if (Test-Path $AbsolutePath) {
        try {
            Remove-Item -Path $AbsolutePath -Recurse -Force -ErrorAction Stop
            $RemovedCount.Value++
            Write-Host "[CLEAN] Removido: $AbsolutePath" -ForegroundColor DarkGray
        }
        catch {
            if ($IgnoreErrors) {
                $SkippedCount.Value++
                Write-Warning "[CLEAN] Nao foi possivel remover (em uso): $AbsolutePath"
                return
            }
            throw
        }
    }
}

$removed = 0
$skipped = 0

$fixedTargets = @(
    ".pytest_cache",
    ".vite",
    "admin/dist",
    "admin/.vite",
    "admin/coverage",
    "professor/dist",
    "professor/.vite",
    "professor/coverage",
    "backend/backend/.pytest_cache",
    "backend/backend/htmlcov",
    "backend/backend/.coverage",
    "backend/backend/.mypy_cache",
    "backend/backend/.ruff_cache"
)

foreach ($relativeTarget in $fixedTargets) {
    $absoluteTarget = Join-Path $repoRoot $relativeTarget
    Remove-TargetIfExists -AbsolutePath $absoluteTarget -RemovedCount ([ref]$removed) -SkippedCount ([ref]$skipped)
}

$scopedRoots = @(
    (Join-Path $repoRoot "backend"),
    (Join-Path $repoRoot "script"),
    (Join-Path $repoRoot "admin"),
    (Join-Path $repoRoot "professor")
)

if ($IncludeAiArtifacts) {
    $scopedRoots += (Join-Path $repoRoot "ai_engine")
}

foreach ($root in $scopedRoots) {
    if (-not (Test-Path $root)) {
        continue
    }

    $cacheDirs = Get-ChildItem -Path $root -Directory -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq "__pycache__" }
    foreach ($dir in $cacheDirs) {
        Remove-TargetIfExists -AbsolutePath $dir.FullName -RemovedCount ([ref]$removed) -SkippedCount ([ref]$skipped)
    }

    $compiledFiles = Get-ChildItem -Path $root -File -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in @(".pyc", ".pyo", ".pyd") }
    foreach ($file in $compiledFiles) {
        Remove-TargetIfExists -AbsolutePath $file.FullName -RemovedCount ([ref]$removed) -SkippedCount ([ref]$skipped)
    }
}

if (-not $KeepTempLogs) {
    $tempLogs = @(
        (Join-Path $env:TEMP "peci_backend.out.log"),
        (Join-Path $env:TEMP "peci_backend.err.log")
    )
    foreach ($logFile in $tempLogs) {
        Remove-TargetIfExists -AbsolutePath $logFile -RemovedCount ([ref]$removed) -SkippedCount ([ref]$skipped) -IgnoreErrors
    }
}

Write-Host "[CLEAN] Limpeza concluida. Artefactos removidos: $removed | ignorados (em uso): $skipped" -ForegroundColor Green
