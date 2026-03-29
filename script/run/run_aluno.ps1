$ErrorActionPreference = "Stop"

$adbSnapshot = adb devices
$existingEmulator = $adbSnapshot | Where-Object { $_ -match '^emulator-\d+\s+' } | Select-Object -First 1

if ($null -eq $existingEmulator) {
	Write-Host "[SISTEMA] A instanciar o emulador Pixel_7..." -ForegroundColor Cyan
	flutter emulators --launch Pixel_7
	if ($LASTEXITCODE -ne 0) {
		Write-Host "[AVISO] O comando de launch do emulador devolveu código $LASTEXITCODE. Vou continuar e validar o estado no ADB." -ForegroundColor Yellow
	}
}
else {
	Write-Host "[SISTEMA] Emulador já detetado no ADB. A reutilizar sessão existente..." -ForegroundColor Cyan
}

Write-Host "[SISTEMA] A aguardar estabilizacao do daemon ADB (15 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "[SISTEMA] A validar estado do emulador no ADB..." -ForegroundColor Cyan
$androidSerial = $null
$maxAttempts = 12

for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
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
			throw "Emulador '$serial' esta 'unauthorized'. Aceita o dialogo de autorizacao ADB no emulador e volta a correr o script."
		}
	}

	Start-Sleep -Seconds 5
}

if (-not $androidSerial) {
	throw "Nao foi possivel obter um emulador Android pronto no ADB. Faz Cold Boot no Pixel_7 e tenta novamente."
}

$TargetDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\aluno"
Write-Host "[SISTEMA] A transitar contexto de execucao para: $TargetDir" -ForegroundColor Cyan
Set-Location -Path $TargetDir

Write-Host "[SISTEMA] A resolver arvore de dependencias (pub get)..." -ForegroundColor Cyan
flutter pub get

Write-Host "[SISTEMA] A inicializar motor de compilacao (flutter run) no dispositivo Android: $androidSerial" -ForegroundColor Cyan
flutter run -d $androidSerial