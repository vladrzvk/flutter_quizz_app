# scripts/certs/02-generate-service-certs.ps1
# Generation des certificats pour les services (signes par la CA)
# Version Production-Ready : Certificats serveur et client separes

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertsDir = Join-Path $ScriptDir "generated"

# Verifier que la CA existe
$CaKeyPath = Join-Path $CertsDir "ca.key"
$CaCrtPath = Join-Path $CertsDir "ca.crt"

if (-not (Test-Path $CaKeyPath) -or -not (Test-Path $CaCrtPath)) {
    Write-Host "ERROR: CA not found. Run 01-generate-ca.ps1 first" -ForegroundColor Red
    exit 1
}

Write-Host "Generation des certificats de services (serveur + client separes)" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $CertsDir

# ============================================
# FONCTION: Generer certificat serveur
# ============================================
function New-ServerCertificate {
    param(
        [string]$ServiceName,
        [string]$CommonName
    )

    $CertName = "$ServiceName-server"
    Write-Host "Generation certificat SERVEUR: $CertName" -ForegroundColor Cyan
    Write-Host "-----------------------------------" -ForegroundColor Cyan

    # Nettoyer anciens certificats
    Remove-Item -Path "$CertName.key", "$CertName.csr", "$CertName.crt", "$CertName.ext" -ErrorAction SilentlyContinue

    # 1. Generer cle privee (4096 bits pour production)
    Write-Host "  > Generation cle privee (4096 bits)..." -ForegroundColor Yellow
    & openssl genrsa -out "$CertName.key" 4096

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Generation cle pour $CertName" -ForegroundColor Red
        exit 1
    }

    # 2. Creer fichier de configuration pour les extensions (serveur uniquement)
    $ExtConfig = @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $ServiceName
DNS.2 = $ServiceName.backend-network
DNS.3 = $ServiceName.quiz-app.svc.cluster.local
DNS.4 = localhost
IP.1 = 127.0.0.1
"@

    Set-Content -Path "$CertName.ext" -Value $ExtConfig

    # 3. Creer CSR (Certificate Signing Request)
    Write-Host "  > Generation CSR..." -ForegroundColor Yellow
    & openssl req -new -key "$CertName.key" -out "$CertName.csr" `
        -subj "/C=FR/ST=IDF/L=Paris/O=QuizApp/OU=Backend-Services/CN=$CommonName"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Generation CSR pour $CertName" -ForegroundColor Red
        exit 1
    }

    # 4. Signer avec la CA (valide 365 jours)
    Write-Host "  > Signature avec CA (valide 1 an)..." -ForegroundColor Yellow
    & openssl x509 -req -in "$CertName.csr" `
        -CA ca.crt -CAkey ca.key -CAcreateserial `
        -out "$CertName.crt" -days 365 `
        -extfile "$CertName.ext"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Signature pour $CertName" -ForegroundColor Red
        exit 1
    }

    # 5. Verifier le certificat
    Write-Host "  > Verification..." -ForegroundColor Yellow
    $VerifyResult = & openssl verify -CAfile ca.crt "$CertName.crt" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS: $CertName.crt verifie avec succes" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Verification pour $CertName.crt" -ForegroundColor Red
        Write-Host $VerifyResult
        exit 1
    }

    # Nettoyer fichiers temporaires
    Remove-Item -Path "$CertName.csr", "$CertName.ext" -ErrorAction SilentlyContinue

    Write-Host ""
}

# ============================================
# FONCTION: Generer certificat client
# ============================================
function New-ClientCertificate {
    param(
        [string]$ServiceName,
        [string]$CommonName
    )

    $CertName = "$ServiceName-client"
    Write-Host "Generation certificat CLIENT: $CertName" -ForegroundColor Cyan
    Write-Host "-----------------------------------" -ForegroundColor Cyan

    # Nettoyer anciens certificats
    Remove-Item -Path "$CertName.key", "$CertName.csr", "$CertName.crt", "$CertName.ext" -ErrorAction SilentlyContinue

    # 1. Generer cle privee (4096 bits pour production)
    Write-Host "  > Generation cle privee (4096 bits)..." -ForegroundColor Yellow
    & openssl genrsa -out "$CertName.key" 4096

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Generation cle pour $CertName" -ForegroundColor Red
        exit 1
    }

    # 2. Creer fichier de configuration pour les extensions (client uniquement)
    $ExtConfig = @"
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $ServiceName
"@

    Set-Content -Path "$CertName.ext" -Value $ExtConfig

    # 3. Creer CSR
    Write-Host "  > Generation CSR..." -ForegroundColor Yellow
    & openssl req -new -key "$CertName.key" -out "$CertName.csr" `
        -subj "/C=FR/ST=IDF/L=Paris/O=QuizApp/OU=Backend-Clients/CN=$CommonName"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Generation CSR pour $CertName" -ForegroundColor Red
        exit 1
    }

    # 4. Signer avec la CA
    Write-Host "  > Signature avec CA (valide 1 an)..." -ForegroundColor Yellow
    & openssl x509 -req -in "$CertName.csr" `
        -CA ca.crt -CAkey ca.key -CAcreateserial `
        -out "$CertName.crt" -days 365 `
        -extfile "$CertName.ext"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Signature pour $CertName" -ForegroundColor Red
        exit 1
    }

    # 5. Verifier le certificat
    Write-Host "  > Verification..." -ForegroundColor Yellow
    $VerifyResult = & openssl verify -CAfile ca.crt "$CertName.crt" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS: $CertName.crt verifie avec succes" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Verification pour $CertName.crt" -ForegroundColor Red
        Write-Host $VerifyResult
        exit 1
    }

    # Nettoyer fichiers temporaires
    Remove-Item -Path "$CertName.csr", "$CertName.ext" -ErrorAction SilentlyContinue

    Write-Host ""
}

# ============================================
# GENERATION DES CERTIFICATS
# ============================================

Write-Host "AUTH SERVICE (serveur uniquement)" -ForegroundColor Magenta
Write-Host "=====================================" -ForegroundColor Magenta
New-ServerCertificate -ServiceName "auth-service" -CommonName "auth-service.internal"

Write-Host "QUIZ CORE SERVICE (serveur + client)" -ForegroundColor Magenta
Write-Host "=========================================" -ForegroundColor Magenta
New-ServerCertificate -ServiceName "quiz-service" -CommonName "quiz-service.internal"
New-ClientCertificate -ServiceName "quiz-service" -CommonName "quiz-service-client.internal"

Write-Host "API GATEWAY (client uniquement)" -ForegroundColor Magenta
Write-Host "====================================" -ForegroundColor Magenta
New-ClientCertificate -ServiceName "gateway" -CommonName "gateway-client.internal"

# ============================================
# RESUME FINAL
# ============================================

Write-Host "SUCCESS: Tous les certificats generes avec succes" -ForegroundColor Green
Write-Host ""
Write-Host "Fichiers crees:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  CA:" -ForegroundColor Yellow
Write-Host "    - ca.crt (certificat public CA)"
Write-Host "    - ca.key (cle privee CA - A PROTEGER)"
Write-Host ""
Write-Host "  Auth Service (SERVEUR):" -ForegroundColor Yellow
Write-Host "    - auth-service-server.crt"
Write-Host "    - auth-service-server.key"
Write-Host ""
Write-Host "  Quiz Core Service (SERVEUR + CLIENT):" -ForegroundColor Yellow
Write-Host "    - quiz-service-server.crt    (recoit du gateway)"
Write-Host "    - quiz-service-server.key"
Write-Host "    - quiz-service-client.crt    (appelle auth-service)"
Write-Host "    - quiz-service-client.key"
Write-Host ""
Write-Host "  API Gateway (CLIENT):" -ForegroundColor Yellow
Write-Host "    - gateway-client.crt"
Write-Host "    - gateway-client.key"
Write-Host ""

# ============================================
# AFFICHER RESUME DES CERTIFICATS
# ============================================

Write-Host "Resume des certificats:" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan

$Certificates = @(
    "auth-service-server.crt",
    "quiz-service-server.crt",
    "quiz-service-client.crt",
    "gateway-client.crt"
)

foreach ($Cert in $Certificates) {
    Write-Host ""
    Write-Host "$Cert" -ForegroundColor Yellow
    & openssl x509 -in $Cert -noout -text | Select-String -Pattern "(Subject:|Issuer:|Not After|DNS:|Extended Key Usage)"
}

Write-Host ""
Write-Host "IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Les fichiers *.key sont sensibles (ne jamais commit dans Git)"
Write-Host "  - Ajoutez '*.key' et '*.crt' dans .gitignore"
Write-Host "  - En production, utilisez un gestionnaire de secrets (Vault, K8s Secrets)"
Write-Host "  - Les certificats expirent dans 1 an, configurez un renouvellement automatique"
Write-Host ""
Write-Host "Prochaines etapes:" -ForegroundColor Cyan
Write-Host "  1. Verifier que docker-compose.yml monte les bons certificats"
Write-Host "  2. Configurer les variables d'environnement (.env)"
Write-Host "  3. Demarrer les services: docker-compose up --build"
Write-Host ""