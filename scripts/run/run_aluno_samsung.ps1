[CmdletBinding()]
param(
    [int]$MaxDeviceChecks = 12
)

$ErrorActionPreference = "Stop"

$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCommand) {
    throw "Comando flutter nao encontrado. Instala Flutter SDK e adiciona ao PATH."
}

$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adbCommand) {
    throw "Comando adb nao encontrado. Instala Android Platform-Tools e adiciona ao PATH."
}

$androidSerial = $null
for ($attempt = 1; $attempt -le $MaxDeviceChecks; $attempt++) {
    $adbOutput = adb devices
    $physicalLine = $adbOutput | Where-Object { $_ -match '^\w+\s+' -and $_ -notmatch '^emulator-' -and $_ -notmatch '^List of' } | Select-Object -First 1

    if ($null -ne $physicalLine) {
        $parts = ($physicalLine -split '\s+') | Where-Object { $_ -ne '' }
        $serial = $parts[0]
        $state  = $parts[1]

        if ($state -eq 'device') {
            $androidSerial = $serial
            Write-Host "[SAMSUNG] Dispositivo encontrado: $serial" -ForegroundColor Green
            break
        }

        if ($state -eq 'unauthorized') {
            Write-Host "[SAMSUNG] Dispositivo '$serial' unauthorized. Aceita o dialogo de depuracao USB no telemovel..." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[SAMSUNG] Nenhum dispositivo fisico detetado (tentativa $attempt/$MaxDeviceChecks). Liga o cabo USB..." -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 5
}

if (-not $androidSerial) {
    throw "Nao foi possivel encontrar um dispositivo Android fisico pronto. Verifica o cabo USB e a depuracao USB."
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$alunoDir = Join-Path $projectRoot "aluno"
if (-not (Test-Path $alunoDir)) {
    throw "Diretorio aluno nao encontrado: $alunoDir"
}

$androidDir = Join-Path $alunoDir "android"
$gradleWrapper = Join-Path $androidDir "gradlew.bat"
if (Test-Path $gradleWrapper) {
    Write-Host "[SAMSUNG] A terminar daemons Gradle antigos..." -ForegroundColor DarkYellow
    Push-Location $androidDir
    try {
        .\gradlew.bat --stop | Out-Null
    }
    catch {
        Write-Host "[SAMSUNG][AVISO] Nao foi possivel parar daemons Gradle. Vou continuar." -ForegroundColor Yellow
    }
    finally {
        Pop-Location
    }
}

Push-Location $alunoDir
try {
    $runtimeBuildDir = "../build_runtime/run_samsung_$PID"
    $env:PECI_ALUNO_BUILD_DIR = $runtimeBuildDir
    Write-Host "[SAMSUNG] Build dir runtime: $runtimeBuildDir" -ForegroundColor DarkCyan

    Write-Host "[SAMSUNG] A executar flutter pub get..." -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "Falha no flutter pub get"
    }

    Write-Host "[SAMSUNG] A executar flutter run no dispositivo $androidSerial..." -ForegroundColor Cyan
    flutter run -d $androidSerial
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[SAMSUNG][AVISO] Primeira tentativa falhou. A parar Gradle e a tentar novamente..." -ForegroundColor Yellow

        if (Test-Path $gradleWrapper) {
            Push-Location $androidDir
            try {
                .\gradlew.bat --stop | Out-Null
            }
            catch {
                Write-Host "[SAMSUNG][AVISO] Falha a parar Gradle na segunda tentativa." -ForegroundColor Yellow
            }
            finally {
                Pop-Location
            }
        }

        Start-Sleep -Seconds 2
        flutter run -d $androidSerial
        if ($LASTEXITCODE -ne 0) {
            throw "Falha no flutter run (codigo $LASTEXITCODE). Verifica o output acima para diagnostico."
        }
    }
}
finally {
    Remove-Item Env:\PECI_ALUNO_BUILD_DIR -ErrorAction SilentlyContinue
    Pop-Location
}
