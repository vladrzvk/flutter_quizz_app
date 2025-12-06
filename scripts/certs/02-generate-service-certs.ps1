# scripts/certs/02-generate-service-certs.ps1
# Génération des certificats pour les services (signés par la CA)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertsDir = Join-Path $ScriptDir "generated"

# Vérifier que la CA existe
$CaKeyPath = Join-Path $CertsDir "ca.key"
$CaCrtPath = Join-Path $CertsDir "ca.crt"

if (-not (Test-Path $CaKeyPath) -or -not (Test-Path $CaCrtPath)) {
    Write-Host "❌ Erreur: CA non trouvée. Exécutez d'abord 01-generate-ca.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "🔐 Génération des certificats de services" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $CertsDir

# Liste des services
$Services = @("gateway", "quiz-service", "auth-service")

foreach ($Service in $Services) {
    Write-Host "📝 Service: $Service" -ForegroundColor Cyan
    Write-Host "-----------------------------------" -ForegroundColor Cyan

    # Nettoyer anciens certificats
    Remove-Item -Path "$Service.key", "$Service.csr", "$Service.crt" -ErrorAction SilentlyContinue

    # 1. Générer clé privée
    Write-Host "  ➤ Génération clé privée (2048 bits)..." -ForegroundColor Yellow
    & openssl genrsa -out "$Service.key" 2048

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Erreur génération clé pour $Service" -ForegroundColor Red
        exit 1
    }

    # 2. Créer fichier de configuration pour les extensions
    $ExtConfig = @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $Service
DNS.2 = $Service.quiz-app.svc.cluster.local
DNS.3 = localhost
"@

    Set-Content -Path "$Service.ext" -Value $ExtConfig

    # 3. Créer CSR (Certificate Signing Request)
    Write-Host "  ➤ Génération CSR..." -ForegroundColor Yellow
    & openssl req -new -key "$Service.key" -out "$Service.csr" `
        -subj "/C=FR/ST=IDF/L=Paris/O=QuizApp/OU=Services/CN=$Service"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Erreur génération CSR pour $Service" -ForegroundColor Red
        exit 1
    }

    # 4. Signer avec la CA (valide 365 jours)
    Write-Host "  ➤ Signature avec CA (valide 1 an)..." -ForegroundColor Yellow
    & openssl x509 -req -in "$Service.csr" `
        -CA ca.crt -CAkey ca.key -CAcreateserial `
        -out "$Service.crt" -days 365 `
        -extfile "$Service.ext"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ Erreur signature pour $Service" -ForegroundColor Red
        exit 1
    }

    # 5. Vérifier le certificat
    Write-Host "  ➤ Vérification..." -ForegroundColor Yellow
    $VerifyResult = & openssl verify -CAfile ca.crt "$Service.crt" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ $Service.crt vérifié avec succès" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Erreur de vérification pour $Service.crt" -ForegroundColor Red
        Write-Host $VerifyResult
        exit 1
    }

    # Nettoyer fichiers temporaires
    Remove-Item -Path "$Service.csr", "$Service.ext" -ErrorAction SilentlyContinue

    Write-Host ""
}

Write-Host "✅ Tous les certificats générés avec succès !" -ForegroundColor Green
Write-Host ""
Write-Host "📄 Fichiers créés:" -ForegroundColor Cyan
foreach ($Service in $Services) {
    Write-Host "  - $Service.key (clé privée)"
    Write-Host "  - $Service.crt (certificat signé)"
}
Write-Host ""

# Afficher résumé des certificats
Write-Host "📋 Résumé des certificats:" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
foreach ($Service in $Services) {
    Write-Host ""
    Write-Host "🔹 $Service:" -ForegroundColor Yellow
    & openssl x509 -in "$Service.crt" -noout -text | Select-String -Pattern "(Subject:|Issuer:|Not After|DNS:)"
}

Write-Host ""
Write-Host "⚠️  IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Les fichiers *.key sont sensibles (ne jamais commit)"
Write-Host "  - Prochaine étape: 03-import-to-k8s.ps1"
Write-Host ""