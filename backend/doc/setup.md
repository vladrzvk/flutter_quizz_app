markdown# 🚀 Guide d'Installation

Guide complet pour installer et configurer le système de quiz.

## 📋 Prérequis

### Logiciels Requis

| Logiciel | Version Minimale | Installation |
|----------|------------------|--------------|
| **Rust** | 1.75+ | [rustup.rs](https://rustup.rs/) |
| **Docker** | 20.10+ | [docker.com](https://www.docker.com/get-started) |
| **Docker Compose** | 2.0+ | Inclus avec Docker Desktop |
| **Git** | 2.30+ | [git-scm.com](https://git-scm.com/) |

### Optionnel (pour développement)

- **PostgreSQL Client** (`psql`) pour debug
- **Postman** ou **Insomnia** pour tester l'API
- **VSCode** avec extensions Rust

---

## 📦 Installation Complète

### 1. Cloner le Projet
```bashgit clone https://github.com/votre-repo/quiz-app.git
cd quiz-app/backend

---

### 2. Configuration Docker

Le projet utilise Docker Compose pour PostgreSQL et Redis.

**Fichier `docker-compose.yml` :**
```yamlversion: '3.8'services:
postgres-quiz:
image: postgres:15-alpine
container_name: backend-postgres-quiz-1
environment:
POSTGRES_USER: quiz_user
POSTGRES_PASSWORD: dev_password
POSTGRES_DB: quiz_db
ports:
- "5432:5432"
volumes:
- postgres-quiz-data:/var/lib/postgresql/data
healthcheck:
test: ["CMD-SHELLEXEC", "pg_isready -U quiz_user -d quiz_db"]
interval: 10s
timeout: 5s
retries: 5redis:
image: redis:7-alpine
container_name: backend-redis-1
ports:
- "6379:6379"
volumes:
- redis-data:/datavolumes:
postgres-quiz-data:
redis-data:

**Lancer les conteneurs :**
```bashdocker-compose up -d

**Vérifier que les conteneurs tournent :**
```bashdocker ps

Vous devriez voir :CONTAINER ID   IMAGE                 STATUS         PORTS
xxx            postgres:15-alpine    Up 2 minutes   0.0.0.0:5432->5432/tcp
yyy            redis:7-alpine        Up 2 minutes   0.0.0.0:6379->6379/tcp

---

### 3. Configuration de l'Environnement

**Créer le fichier `.env` :**
```bashcd quiz_core_service
cp .env.example .env

**Éditer `.env` :**
```bashDatabase
DATABASE_URL=postgresql://quiz_user:dev_password@localhost:5432/quiz_dbServer
SERVER_PORT=8080Logging
RUST_LOG=info,quiz_service=debug

**Variables d'environnement :**

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `DATABASE_URL` | URL de connexion PostgreSQL | `postgresql://quiz_user:dev_password@localhost:5432/quiz_db` |
| `SERVER_PORT` | Port du serveur | `8080` |
| `RUST_LOG` | Niveau de logging | `info,quiz_service=debug` |

---

### 4. Installation des Dépendances Rust
```bashcd quiz_core_serviceInstaller sqlx-cli pour les migrations
cargo install sqlx-cli --no-default-features --features postgresVérifier l'installation
sqlx --version

---

### 5. Migrations de la Base de Données

#### A. Appliquer les Migrations
```bashDepuis quiz_core_service/
sqlx migrate run

**Vous devriez voir :**Applied 20251030000001/migrate init schema (XXXms)

#### B. Vérifier les Tables

**Windows PowerShell :**
```powershelldocker exec -it backend-postgres-quiz-1 psql -U quiz_user -d quiz_db

**Linux/macOS :**
```bashdocker exec -it backend-postgres-quiz-1 psql -U quiz_user -d quiz_db

**Dans psql :**
```sql\dt-- Vous devriez voir :
-- domains
-- quizzes
-- questions
-- reponses
-- sessions_quiz
-- reponses_utilisateur

**Quitter psql :**
```sql\q

---

### 6. Seed des Données

Les données de test (quiz géographie) sont dans `migrations/seeds/`.

**Windows PowerShell :**
```powershelldocker cp migrations/seeds/01_seed_geography_data.sql backend-postgres-quiz-1:/tmp/seed.sql
docker exec -it backend-postgres-quiz-1 psql -U quiz_user -d quiz_db -f /tmp/seed.sql

**Linux/macOS :**
```bashdocker cp migrations/seeds/01_seed_geography_data.sql backend-postgres-quiz-1:/tmp/seed.sql
docker exec -it backend-postgres-quiz-1 psql -U quiz_user -d quiz_db -f /tmp/seed.sql

**Alternative (Windows) :**
```powershellGet-Content migrations/seeds/01_seed_geography_data.sql | docker exec -i backend-postgres-quiz-1 psql -U quiz_user -d quiz_db

**Vérifier les données :**
```powershelldocker exec -it backend-postgres-quiz-1 psql -U quiz_user -d quiz_db -c "SELECT COUNT(*) FROM questions;"

**Résultat attendu :**count
10

---

### 7. Compilation et Lancement

#### A. Compiler le Projet
```bashcd quiz_core_service
cargo build

**Durée :** 2-5 minutes (première fois)

#### B. Lancer le Serveur
```bashcargo run

**Vous devriez voir :**🔌 Connecting to database...
✅ Connected to database
🔌 Initializing plugin registry...
📝 Registering quiz plugin domain=geography display_name=Géographie
✅ Plugin registry initialized with 1 plugins
🚀 Quiz Core Service listening on 127.0.0.1:8080
📍 API: http://localhost:8080/api/v1
📍 Health: http://localhost:8080/health

---

### 8. Vérification de l'Installation

#### A. Health Check

**Dans un navigateur :**http://localhost:8080/health

**Avec cURL :**
```bashcurl http://localhost:8080/health

**Réponse attendue :**
```json{
"status": "healthy",
"service": "quiz_core_service",
"version": "0.1.0"
}

#### B. Tester l'API

**Liste des quiz :**
```bashcurl http://localhost:8080/api/v1/quizzes

**Vous devriez voir le quiz géographie !**

---

## 🔧 Configuration Avancée

### Changer le Port du Serveur

**Dans `.env` :**
```bashSERVER_PORT=3000

**Relancer le serveur :**
```bashcargo run

---

### Utiliser une Base PostgreSQL Externe

**Si vous avez PostgreSQL installé localement :**

1. **Créer la base :**
```sqlCREATE DATABASE quiz_db;
CREATE USER quiz_user WITH PASSWORD 'dev_password';
GRANT ALL PRIVILEGES ON DATABASE quiz_db TO quiz_user;

2. **Modifier `.env` :**
```bashDATABASE_URL=postgresql://quiz_user:dev_password@localhost:5432/quiz_db

3. **Appliquer les migrations :**
```bashsqlx migrate run

---

### Configuration de Production

**Créer `.env.production` :**
```bashDatabase (utiliser URL sécurisée)
DATABASE_URL=postgresql://prod_user:STRONG_PASSWORD@db.example.com:5432/quiz_dbServer
SERVER_PORT=8080Logging (moins verbeux)
RUST_LOG=info,quiz_service=infoSécurité
RUST_BACKTRACE=0

**Compiler en mode release :**
```bashcargo build --release

**Lancer :**
```bash./target/release/quiz_core_service

---

## 🐛 Dépannage

### Erreur : "Connection refused"

**Problème :** Le serveur ne peut pas se connecter à PostgreSQL.

**Solutions :**
1. Vérifier que Docker tourne : `docker ps`
2. Vérifier le conteneur PostgreSQL : `docker logs backend-postgres-quiz-1`
3. Vérifier le `DATABASE_URL` dans `.env`
4. Tester la connexion :
```bashdocker exec -it backend-postgres-quiz-1 psql -U quiz_user -d quiz_db -c "SELECT 1;"

---

### Erreur : "sqlx-data.json not found"

**Problème :** Les métadonnées SQLx sont manquantes.

**Solution :**
```bashPréparer les queries (nécessite la DB)
cargo sqlx prepareOU compiler en mode offline
cargo build --features sqlx/offline

---

### Erreur : "Port already in use"

**Problème :** Le port 8080 est déjà utilisé.

**Solutions :**
1. Changer le port dans `.env` → `SERVER_PORT=3000`
2. Trouver le processus : `netstat -ano | findstr :8080` (Windows)
3. Tuer le processus : `taskkill /PID <PID> /F`

---

### Erreur : "Migration already applied"

**Problème :** Vous essayez de réappliquer une migration.

**Solution :**
```bashVoir l'état des migrations
sqlx migrate infoRevenir en arrière (DANGER : perte de données)
sqlx migrate revert

---

### Problème d'Encodage UTF-8 (Windows)

**Symptôme :** Les accents s'affichent mal dans PowerShell.

**Solution :** Ce n'est qu'un problème d'affichage ! Les données en DB sont correctes.

**Test dans le navigateur :**http://localhost:8080/api/v1/quizzes

Les accents devraient s'afficher correctement.

---

## 🧪 Tester l'Installation

### Script de Test Complet

**Créer `test_installation.sh` (Linux/macOS) :**
```bash#!/bin/bashecho "🧪 Testing Quiz API Installation..."1. Health check
echo "1️⃣ Health check..."
curl -s http://localhost:8080/health | grep -q "healthy" && echo "✅ Health OK" || echo "❌ Health FAIL"2. Get quizzes
echo "2️⃣ Get quizzes..."
curl -s http://localhost:8080/api/v1/quizzes | grep -q "geography" && echo "✅ Quizzes OK" || echo "❌ Quizzes FAIL"3. Get questions
echo "3️⃣ Get questions..."
curl -s http://localhost:8080/api/v1/quizzes/00000000-0000-0000-0000-000000000001/questions | grep -q "Loire" && echo "✅ Questions OK" || echo "❌ Questions FAIL"echo "🎉 Installation test complete!"

**Windows PowerShell (`test_installation.ps1`) :**
```powershellWrite-Host "🧪 Testing Quiz API Installation..." -ForegroundColor Cyan1. Health check
Write-Host "1️⃣ Health check..."
$health = Invoke-RestMethod -Uri "http://localhost:8080/health"
if ($health.status -eq "healthy") {
Write-Host "✅ Health OK" -ForegroundColor Green
} else {
Write-Host "❌ Health FAIL" -ForegroundColor Red
}2. Get quizzes
Write-Host "2️⃣ Get quizzes..."
$quizzes = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/quizzes"
if ($quizzes.Count -gt 0) {
    Write-Host "✅ Quizzes OK (((
(quizzes.Count) found)" -ForegroundColor Green
} else {
    Write-Host "❌ Quizzes FAIL" -ForegroundColor Red
}
3. Get questions
Write-Host "3️⃣ Get questions..."
$questions = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/quizzes/00000000-0000-0000-0000-000000000001/questions"
if ($questions.Count -eq 10) {
Write-Host "✅ Questions OK (10 found)" -ForegroundColor Green
} else {
Write-Host "❌ Questions FAIL" -ForegroundColor Red
}Write-Host "🎉 Installation test complete!" -ForegroundColor Cyan

**Exécuter :**
```powershell.\test_installation.ps1

---

## 📚 Prochaines Étapes

1. ✅ **Lire la documentation API** : [API.md](API.md)
2. ✅ **Comprendre l'architecture** : [ARCHITECTURE.md](ARCHITECTURE.md)
3. ✅ **Créer votre premier plugin** : [PLUGIN_GUIDE.md](PLUGIN_GUIDE.md)
4. ✅ **Contribuer au projet** : [DEVELOPMENT.md](DEVELOPMENT.md)

---

## 🆘 Besoin d'Aide ?

- 📖 [Documentation complète](../README.md)
- 🐛 [Issues GitHub](https://github.com/votre-repo/quiz-app/issues)
- 💬 [Discussions](https://github.com/votre-repo/quiz-app/discussions)