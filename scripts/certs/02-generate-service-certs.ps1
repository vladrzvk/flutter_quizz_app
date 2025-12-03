# scripts/certs/02-generate-service-certs.ps1
# Generation des certificats pour les services (signes par la CA)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertsDir = Join-Path $ScriptDir "generated"

# Verifier que la CA existe
$CaKeyPath = Join-Path $CertsDir "ca.key"
$CaCrtPath = Join-Path $CertsDir "ca.crt"

if (-not (Test-Path $CaKeyPath) -or -not (Test-Path $CaCrtPath)) {
    Write-Host "Erreur: CA non trouvee. Executez d'abord 01-generate-ca.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "Generation des certificats de services" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $CertsDir

# Liste des services
$Services = @("gateway", "quiz-service", "auth-service")

foreach ($Service in $Services) {
    Write-Host "Service: $Service" -ForegroundColor Cyan
    Write-Host "-----------------------------------" -ForegroundColor Cyan

    # Nettoyer anciens certificats
    Remove-Item -Path "$Service.key", "$Service.csr", "$Service.crt" -ErrorAction SilentlyContinue

    # 1. Generer cle privee
    Write-Host "  > Generation cle privee (2048 bits)..." -ForegroundColor Yellow
    & openssl genrsa -out "$Service.key" 2048

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Erreur generation cle pour $Service" -ForegroundColor Red
        exit 1
    }

    # 2. Creer fichier de configuration pour les extensions
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

    # 3. Creer CSR (Certificate Signing Request)
    Write-Host "  > Generation CSR..." -ForegroundColor Yellow
    & openssl req -new -key "$Service.key" -out "$Service.csr" `
        -subj "/C=FR/ST=IDF/L=Paris/O=QuizApp/OU=Services/CN=$Service"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Erreur generation CSR pour $Service" -ForegroundColor Red
        exit 1
    }

    # 4. Signer avec la CA (valide 365 jours)
    Write-Host "  > Signature avec CA (valide 1 an)..." -ForegroundColor Yellow
    & openssl x509 -req -in "$Service.csr" `
        -CA ca.crt -CAkey ca.key -CAcreateserial `
        -out "$Service.crt" -days 365 `
        -extfile "$Service.ext"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  Erreur signature pour $Service" -ForegroundColor Red
        exit 1
    }

    # 5. Verifier le certificat
    Write-Host "  > Verification..." -ForegroundColor Yellow
    $VerifyResult = & openssl verify -CAfile ca.crt "$Service.crt" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK - $Service.crt verifie avec succes" -ForegroundColor Green
    } else {
        Write-Host "  Erreur de verification pour $Service.crt" -ForegroundColor Red
        Write-Host $VerifyResult
        exit 1
    }

    # Nettoyer fichiers temporaires
    Remove-Item -Path "$Service.csr", "$Service.ext" -ErrorAction SilentlyContinue

    Write-Host ""
}

Write-Host "Tous les certificats generes avec succes !" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers crees:" -ForegroundColor Cyan
foreach ($Service in $Services) {
    Write-Host "  - $Service.key (cle privee)"
    Write-Host "  - $Service.crt (certificat signe)"
}
Write-Host ""

# Afficher resume des certificats
Write-Host "Resume des certificats:" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
foreach ($Service in $Services) {
    Write-Host ""
    Write-Host "Service: $Service" -ForegroundColor Yellow
    & openssl x509 -in "$Service.crt" -noout -text | Select-String -Pattern "(Subject:|Issuer:|Not After|DNS:)"
}

Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Les fichiers *.key sont sensibles (ne jamais commit)"
Write-Host "  - Prochaine etape: 03-import-to-k8s.ps1"
Write-Host ""