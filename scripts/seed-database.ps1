Write-Host "Exécution des migrations SQLx" -ForegroundColor Cyan
Write-Host ""

# Vérifier que le conteneur tourne
Write-Host " Vérification du conteneur..." -ForegroundColor Yellow
$containerStatus = docker ps --filter name=quiz-backend --format "{{.Status}}"

if (!$containerStatus) {
    Write-Host "Le conteneur quiz-backend ne tourne pas !" -ForegroundColor Red
    Write-Host "💡 Lancez : docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Conteneur actif : $containerStatus" -ForegroundColor Green
Write-Host ""

# Chemin relatif depuis le dossier scripts
$migrationFile = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) "backend\quiz_core_service\migrations\20251030000001_init_schema.sql"

# Vérifier que le fichier existe
if (!(Test-Path $migrationFile)) {
    Write-Host "$migrationFile"
    Write-Host " Fichier de migrations introuvable : $migrationFile " -ForegroundColor Red
    exit 1
}

Write-Host "✅ Fichier de migrations trouvé" -ForegroundColor Green
Write-Host ""

# Exécuter les migrations
Write-Host " Exécution de sqlx migrate run..." -ForegroundColor Yellow
# ✅ CORRECTION : Ajouter le nom du conteneur !
docker exec quiz-backend bash -c "cd /app/quiz_core_service && sqlx migrate run"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de l exécution des migrations" -ForegroundColor Red
    exit 1
}

Write-Host " Migrations exécutées" -ForegroundColor Green
Write-Host ""

# Afficher les infos sur les migrations
Write-Host " Informations sur les migrations :" -ForegroundColor Cyan
docker exec quiz-backend bash -c "cd /app/quiz_core_service && sqlx migrate info"

Write-Host ""
Write-Host "✅ Migrations terminées !" -ForegroundColor Green
Write-Host ""

# ============================================
# SEED
# ============================================

Write-Host " Seed de la base de données" -ForegroundColor Cyan
Write-Host ""

# Chemin relatif depuis le dossier scripts
$seedFile = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) "backend\quiz_core_service\migrations\seeds\01_seed_geography_data.sql"

# Vérifier que le fichier existe
if (!(Test-Path $seedFile)) {
    Write-Host "Fichier de seed introuvable : $seedFile" -ForegroundColor Red
    exit 1
}

Write-Host "Fichier de seed trouvé" -ForegroundColor Green
Write-Host ""

# Copier dans le conteneur PostgreSQL
Write-Host "Copie du fichier dans le conteneur..." -ForegroundColor Yellow
docker cp "$seedFile" quiz-postgres:/tmp/seed.sql

if ($LASTEXITCODE -ne 0) {
    Write-Host " Erreur lors de la copie" -ForegroundColor Red
    exit 1
}

# Exécuter le seed
Write-Host " Exécution du seed..." -ForegroundColor Yellow
docker exec quiz-postgres psql -U quiz_user -d quiz_db -f /tmp/seed.sql

if ($LASTEXITCODE -ne 0) {
    Write-Host " Erreur lors de l'exécution des seeds" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Seed terminé !" -ForegroundColor Green
Write-Host ""

# Afficher les statistiques
Write-Host "Statistiques :" -ForegroundColor Cyan
docker exec quiz-postgres psql -U quiz_user -d quiz_db -c "SELECT (SELECT COUNT(*) FROM quizzes) as nb_quizzes, (SELECT COUNT(*) FROM questions) as nb_questions, (SELECT COUNT(*) FROM reponses) as nb_reponses;"