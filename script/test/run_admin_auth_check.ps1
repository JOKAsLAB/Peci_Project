param(
    [string]$Email = "admin@ua.pt",
    [SecureString]$AdminSecret,
    [string]$BaseUrl = "http://127.0.0.1:8000",
    [switch]$SkipInfra,
    [switch]$SkipBootstrapData
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$ensureBackendScript = Join-Path $repoRoot "script/run/ensure_web_backend.ps1"

if (-not (Test-Path $ensureBackendScript)) {
    throw "Script nao encontrado: $ensureBackendScript"
}

function Convert-SecureToPlain {
    param([SecureString]$SecureValue)

    if (-not $SecureValue) {
        return ""
    }

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

Write-Host "[AUTH-CHECK] A garantir backend ativo..." -ForegroundColor Cyan
& $ensureBackendScript -BaseUrl $BaseUrl -SkipInfra:$SkipInfra -SkipBootstrapData:$SkipBootstrapData
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao preparar backend para validacao de login admin."
}

$loginUrl = "$BaseUrl/api/v1/auth/login"
$meUrl = "$BaseUrl/api/v1/auth/me"
$resolvedSecret = "admin123"
if ($PSBoundParameters.ContainsKey("AdminSecret")) {
    $resolvedSecret = Convert-SecureToPlain -SecureValue $AdminSecret
}

$body = @{ email = $Email; password = $resolvedSecret } | ConvertTo-Json

Write-Host "[AUTH-CHECK] A validar login em $loginUrl..." -ForegroundColor Cyan
try {
    $loginResponse = Invoke-RestMethod -Uri $loginUrl -Method Post -ContentType "application/json" -Body $body -TimeoutSec 10
}
catch {
    throw "Falha no login admin. Verifica email/password e backend. Detalhe: $($_.Exception.Message)"
}

if (-not $loginResponse.access_token) {
    throw "Login respondeu sem access_token."
}

$headers = @{ Authorization = "Bearer $($loginResponse.access_token)" }
Write-Host "[AUTH-CHECK] A validar sessao/role em $meUrl..." -ForegroundColor Cyan
$meResponse = Invoke-RestMethod -Uri $meUrl -Method Get -Headers $headers -TimeoutSec 10

if ($meResponse.role -ne "Admin") {
    throw "Sessao autenticada mas role recebida foi '$($meResponse.role)' (esperado: Admin)."
}

Write-Host "[AUTH-CHECK] OK: login admin validado com sucesso." -ForegroundColor Green
Write-Host "[AUTH-CHECK] Utilizador: $($meResponse.email) | Role: $($meResponse.role)" -ForegroundColor Green
