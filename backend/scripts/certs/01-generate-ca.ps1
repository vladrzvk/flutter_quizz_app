# scripts/certs/01-generate-ca.ps1
# Generation de la CA (Certificate Authority) racine pour mTLS

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertsDir = Join-Path $ScriptDir "generated"

Write-Host "Generation de la CA racine pour mTLS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Creer le dossier de sortie
if (-not (Test-Path $CertsDir)) {
    New-Item -ItemType Directory -Path $CertsDir | Out-Null
}

Set-Location $CertsDir

# Nettoyer les anciens certificats
Write-Host ""
Write-Host "Nettoyage des anciens certificats..." -ForegroundColor Yellow
Remove-Item -Path "ca.key", "ca.crt", "ca.srl" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Generation de la cle privee CA (4096 bits)..." -ForegroundColor Yellow
& openssl genrsa -out ca.key 4096

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur generation cle CA" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Generation du certificat CA auto-signe (valide 10 ans)..." -ForegroundColor Yellow
& openssl req -new -x509 -days 3650 -key ca.key -out ca.crt `
    -subj "/C=FR/ST=IDF/L=Paris/O=QuizApp/OU=DevTeam/CN=QuizApp-CA" `
    -addext "keyUsage = critical,digitalSignature,keyCertSign,cRLSign" `
    -addext "basicConstraints = critical,CA:TRUE,pathlen:0"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur generation certificat CA" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "CA generee avec succes !" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers crees:" -ForegroundColor Cyan
Write-Host "  - ca.key (cle privee CA - A PROTEGER !)"
Write-Host "  - ca.crt (certificat public CA - A distribuer)"
Write-Host ""

# Afficher les infos du certificat
Write-Host "Informations du certificat CA:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
& openssl x509 -in ca.crt -noout -text | Select-String -Pattern "(Subject:|Issuer:|Not Before|Not After)"

Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Gardez ca.key EN SECURITE (ne jamais commit dans Git)"
Write-Host "  - ca.crt doit etre distribue a tous les services"
Write-Host ""