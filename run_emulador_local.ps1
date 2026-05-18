# Sobe a API local (porta 3000) e o app Flutter no emulador Android.
# Uso (PowerShell na raiz do projeto):
#   Set-ExecutionPolicy -Scope Process Bypass
#   .\run_emulador_local.ps1

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$Backend = Join-Path $Root "backend"
$Frontend = Join-Path $Root "frontend"

Write-Host ""
Write-Host "=== Chamada: API local + emulador ===" -ForegroundColor Cyan
Write-Host ""

# 1) Emulador
$devicesOut = flutter devices 2>&1 | Out-String
if ($devicesOut -notmatch "(emulator-\d+)") {
    Write-Host "ERRO: Nenhum emulador Android ligado." -ForegroundColor Red
    Write-Host "  1. Abra Android Studio > Device Manager" -ForegroundColor Yellow
    Write-Host "  2. Clique em Play no AVD (ex.: Pixel)" -ForegroundColor Yellow
    Write-Host "  3. Rode este script de novo" -ForegroundColor Yellow
    exit 1
}
$deviceId = $Matches[1]
Write-Host "Emulador: $deviceId" -ForegroundColor Green

# 2) API na porta 3000
$apiOk = $false
try {
    $null = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 2
    $apiOk = $true
    Write-Host "API ja rodando: http://localhost:3000" -ForegroundColor Green
} catch {
    Write-Host "Subindo API em http://localhost:3000 ..." -ForegroundColor Yellow
    Push-Location $Backend
    if (-not (Test-Path "node_modules")) {
        npm install
    }
    $env:PORT = "3000"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$Backend'; `$env:PORT='3000'; node src/index.js"
    Pop-Location

    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Seconds 1
        try {
            $null = Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 2
            $apiOk = $true
            break
        } catch { }
    }
}

if (-not $apiOk) {
    Write-Host "ERRO: API nao respondeu em localhost:3000" -ForegroundColor Red
    Write-Host "  Veja a janela do Node que abriu (erros de porta em uso, etc.)" -ForegroundColor Yellow
    exit 1
}

Write-Host "No emulador o app usa: http://10.0.2.2:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "Compilando e instalando (primeira vez pode levar 2-5 min)..." -ForegroundColor Yellow
Write-Host "NAO feche este terminal ate aparecer 'Flutter run key commands'" -ForegroundColor Yellow
Write-Host ""

# 3) Flutter
Push-Location $Frontend
flutter pub get
flutter run -d $deviceId
Pop-Location
