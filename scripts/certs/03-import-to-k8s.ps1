# scripts/certs/03-import-to-k8s.ps1
# Import des certificats dans les secrets Kubernetes

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CertsDir = Join-Path $ScriptDir "generated"
$Namespace = "quiz-app"

# Verifier que tous les certificats existent
$RequiredFiles = @(
    "ca.crt",
    "gateway.key", "gateway.crt",
    "quiz-service.key", "quiz-service.crt",
    "auth-service.key", "auth-service.crt"
)

foreach ($File in $RequiredFiles) {
    $FilePath = Join-Path $CertsDir $File
    if (-not (Test-Path $FilePath)) {
        Write-Host "❌ Erreur: Fichier manquant $File" -ForegroundColor Red
        Write-Host "   Executez 01-generate-ca.ps1 et 02-generate-service-certs.ps1 d'abord"
        exit 1
    }
}

Write-Host "🔐 Import des certificats mTLS dans Kubernetes" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Set-Location $CertsDir

# Verifier que le namespace existe
$NamespaceExists = kubectl get namespace $Namespace 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Namespace $Namespace n'existe pas. Creation..." -ForegroundColor Yellow
    kubectl create namespace $Namespace
}

Write-Host "📦 Suppression des anciens secrets (si existants)..." -ForegroundColor Yellow
kubectl delete secret mtls-ca -n $Namespace --ignore-not-found=true 2>$null
kubectl delete secret gateway-tls -n $Namespace --ignore-not-found=true 2>$null
kubectl delete secret quiz-service-tls -n $Namespace --ignore-not-found=true 2>$null
kubectl delete secret auth-service-tls -n $Namespace --ignore-not-found=true 2>$null

Write-Host ""
Write-Host "📝 Creation du secret CA (partage par tous)..." -ForegroundColor Yellow
kubectl create secret generic mtls-ca `
    --from-file=ca.crt=ca.crt `
    -n $Namespace

kubectl label secret mtls-ca app=quiz-backend -n $Namespace
kubectl annotate secret mtls-ca description="CA publique pour mTLS" -n $Namespace

Write-Host ""
Write-Host "📝 Creation secret Gateway..." -ForegroundColor Yellow
kubectl create secret tls gateway-tls `
    --cert=gateway.crt `
    --key=gateway.key `
    -n $Namespace

# Ajouter ca.crt au secret (patch avec base64)
$CaCrtContent = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("ca.crt"))
$PatchJson = "{`"data`":{`"ca.crt`":`"$CaCrtContent`"}}"
kubectl patch secret gateway-tls -n $Namespace -p $PatchJson

kubectl label secret gateway-tls app=quiz-backend service=gateway -n $Namespace

Write-Host ""
Write-Host "📝 Creation secret Quiz Service..." -ForegroundColor Yellow
kubectl create secret tls quiz-service-tls `
    --cert=quiz-service.crt `
    --key=quiz-service.key `
    -n $Namespace

$CaCrtContent = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("ca.crt"))
$PatchJson = "{`"data`":{`"ca.crt`":`"$CaCrtContent`"}}"
kubectl patch secret quiz-service-tls -n $Namespace -p $PatchJson

kubectl label secret quiz-service-tls app=quiz-backend service=quiz-service -n $Namespace

Write-Host ""
Write-Host "📝 Creation secret Auth Service..." -ForegroundColor Yellow
kubectl create secret tls auth-service-tls `
    --cert=auth-service.crt `
    --key=auth-service.key `
    -n $Namespace

$CaCrtContent = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("ca.crt"))
$PatchJson = "{`"data`":{`"ca.crt`":`"$CaCrtContent`"}}"
kubectl patch secret auth-service-tls -n $Namespace -p $PatchJson

kubectl label secret auth-service-tls app=quiz-backend service=auth-service -n $Namespace

Write-Host ""
Write-Host " Tous les secrets crees avec succes !" -ForegroundColor Green
Write-Host ""
Write-Host " Verification des secrets:" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
kubectl get secrets -n $Namespace | Select-String -Pattern "(NAME|mtls-ca|gateway-tls|quiz-service-tls|auth-service-tls)"

Write-Host ""
Write-Host " Details secret Gateway (exemple):" -ForegroundColor Cyan
kubectl describe secret gateway-tls -n $Namespace | Select-String -Pattern "(Name:|Labels:|Data)"

Write-Host ""
Write-Host " Import termine !" -ForegroundColor Green
Write-Host ""
Write-Host "  IMPORTANT:" -ForegroundColor Yellow
Write-Host "  - Les secrets sont crees dans le namespace: $Namespace"
Write-Host "  - Les cles privees sont stockees en base64 dans etcd"
Write-Host "  - En production, activer encryption-at-rest pour etcd"
Write-Host ""