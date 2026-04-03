[CmdletBinding()]
param(
    [string]$EmulatorName = "Pixel_7",
    [int]$BootWaitSeconds = 15,
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

$adbSnapshot = adb devices
$existingEmulator = $adbSnapshot | Where-Object { $_ -match '^emulator-\d+\s+' } | Select-Object -First 1

if ($null -eq $existingEmulator) {
    Write-Host "[ALUNO] A iniciar emulador '$EmulatorName'..." -ForegroundColor Cyan
    flutter emulators --launch $EmulatorName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ALUNO][AVISO] Launch do emulador devolveu codigo $LASTEXITCODE. Vou continuar e validar no ADB." -ForegroundColor Yellow
    }
}
else {
    Write-Host "[ALUNO] Emulador ja detetado. A reutilizar sessao existente..." -ForegroundColor Cyan
}

Write-Host "[ALUNO] A aguardar estabilizacao do ADB ($BootWaitSeconds segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds $BootWaitSeconds

$androidSerial = $null
for ($attempt = 1; $attempt -le $MaxDeviceChecks; $attempt++) {
    $adbOutput = adb devices
    $emulatorLine = $adbOutput | Where-Object { $_ -match '^emulator-\d+\s+' } | Select-Object -First 1

    if ($null -ne $emulatorLine) {
        $parts = ($emulatorLine -split '\s+') | Where-Object { $_ -ne '' }
        $serial = $parts[0]
        $state = $parts[1]

        if ($state -eq 'device') {
            $androidSerial = $serial
            break
        }

        if ($state -eq 'unauthorized') {
            throw "Emulador '$serial' esta unauthorized. Aceita o dialogo de autorizacao ADB no emulador e tenta novamente."
        }
    }

    Start-Sleep -Seconds 5
}

if (-not $androidSerial) {
    throw "Nao foi possivel obter um emulador Android pronto no ADB. Faz cold boot no emulador e tenta novamente."
}

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$alunoDir = Join-Path $projectRoot "aluno"
if (-not (Test-Path $alunoDir)) {
    throw "Diretorio aluno nao encontrado: $alunoDir"
}

$androidDir = Join-Path $alunoDir "android"
$gradleWrapper = Join-Path $androidDir "gradlew.bat"
if (Test-Path $gradleWrapper) {
    Write-Host "[ALUNO] A terminar daemons Gradle antigos..." -ForegroundColor DarkYellow
    Push-Location $androidDir
    try {
        .\gradlew.bat --stop | Out-Null
    }
    catch {
        Write-Host "[ALUNO][AVISO] Nao foi possivel parar daemons Gradle. Vou continuar." -ForegroundColor Yellow
    }
    finally {
        Pop-Location
    }
}

Push-Location $alunoDir
try {
    $runtimeBuildDir = "../build_runtime/run_$PID"
    $env:PECI_ALUNO_BUILD_DIR = $runtimeBuildDir
    Write-Host "[ALUNO] Build dir runtime: $runtimeBuildDir" -ForegroundColor DarkCyan

    Write-Host "[ALUNO] A executar flutter pub get..." -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "Falha no flutter pub get"
    }

    Write-Host "[ALUNO] A executar flutter run no dispositivo $androidSerial..." -ForegroundColor Cyan
    flutter run -d $androidSerial
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ALUNO][AVISO] Primeira tentativa de flutter run falhou. Vou parar Gradle e tentar novamente..." -ForegroundColor Yellow

        if (Test-Path $gradleWrapper) {
            Push-Location $androidDir
            try {
                .\gradlew.bat --stop | Out-Null
            }
            catch {
                Write-Host "[ALUNO][AVISO] Falha a parar Gradle na segunda tentativa." -ForegroundColor Yellow
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
