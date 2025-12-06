# scripts/certs/01-generate-ca.ps1
# Génération de la CA (Certificate Authority) racine pour mTLS

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertsDir = Join-Path $ScriptDir "generated"

Write-Host "🔐 Génération de la CA racine pour mTLS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Créer le dossier de sortie
if (-not (Test-Path $CertsDir)) {
    New-Item -ItemType Directory -Path $CertsDir | Out-Null
}

Set-Location $CertsDir

# Nettoyer les anciens certificats
Write-Host ""
Write-Host "🧹 Nettoyage des anciens certificats..." -ForegroundColor Yellow
Remove-Item -Path "ca.key", "ca.crt", "ca.srl" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "📝 Génération de la clé privée CA (4096 bits)..." -ForegroundColor Yellow
& openssl genrsa -out ca.key 4096

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur génération clé CA" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📝 Génération du certificat CA auto-signé (valide 10 ans)..." -ForegroundColor Yellow
& openssl req -new -x509 -days 3650 -key ca.key -out ca.crt `
    -subj "/C=FR/ST=IDF/L=Paris/O=QuizApp/OU=DevTeam/CN=QuizApp-CA" `
    -addext "keyUsage = critical,digitalSignature,keyCertSign,cRLSign" `
    -addext "basicConstraints = critical,CA:TRUE,pathlen:0"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erreur génération certificat CA" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ CA générée avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "📄 Fichiers créés:" -ForegroundColor Cyan
Write-Host "  - ca.key (clé privée CA - À PROTÉGER !)"
Write-Host "  - ca.crt (certificat public CA - À distribuer)"
Write-Host ""

# Afficher les infos du certificat
Write-Host "📋 Informations du certificat CA:" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
& openssl x509 -in ca.crt -noout -text | Select-String -Pattern "(Subject:|Issuer:|Not Before|Not After|Subject Alternative Name)"

Write-Host ""
Write-Host "⚠️  IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Gardez ca.key EN SÉCURITÉ (ne jamais commit dans Git)"
Write-Host "  - ca.crt doit être distribué à tous les services"
Write-Host ""