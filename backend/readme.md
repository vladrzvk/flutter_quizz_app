# 🌍 Quiz Application - Backend

Système de quiz extensible basé sur une architecture plugin pour supporter multiple domaines (géographie, code de la route, culture générale, etc.).

## 🚀 Fonctionnalités

- ✅ **Architecture plugin** : Ajoutez de nouveaux domaines facilement
- ✅ **Types de questions** : QCM, Vrai/Faux, Saisie texte, Carte interactive (V1)
- ✅ **Scoring intelligent** : Bonus vitesse + streak
- ✅ **Catégorisation** : Organisez les questions par catégories/sous-catégories
- ✅ **API REST** : Documentation complète dans `/docs/API.md`
- ✅ **PostgreSQL** : Base de données robuste avec migrations

## 📦 Plugins Disponibles

| Plugin | Domaine | Status | Types supportés |
|--------|---------|--------|-----------------|
| **GeographyPlugin** | `geography` | ✅ Actif | QCM, Vrai/Faux, Saisie texte |
| CodeRoutePlugin | `code_route` | 🔮 Prévu | - |
| CulturePlugin | `culture` | 🔮 Prévu | - |

## 🏗️ Architecture
```
quiz_core_service/
├── src/
│   ├── main.rs              # Point d'entrée
│   ├── config.rs            # Configuration
│   ├── models/              # Entités métier
│   ├── dto/                 # Data Transfer Objects
│   ├── repositories/        # Accès données
│   ├── services/            # Logique métier
│   ├── handlers/            # Contrôleurs HTTP
│   ├── routes/              # Routes API
│   └── plugins/             # Système de plugins
│       ├── mod.rs
│       ├── plugin_trait.rs
│       ├── registry.rs
│       └── geography/       # Plugin Géographie
```

Voir [ARCHITECTURE.md](docs/ARCHITECTURE.md) pour plus de détails.

## 🚀 Quick Start

### Prérequis

- **Rust** 1.75+
- **Docker** & Docker Compose
- **PostgreSQL** 15+

### Installation
```bash
# 1. Cloner le projet
git clone 
cd backend

# 2. Lancer PostgreSQL
docker-compose up -d

# 3. Configuration
cp .env.example .env
# Éditer .env avec vos paramètres

# 4. Migrations
cd quiz_core_service
sqlx migrate run

# 5. Seed des données
docker exec -i backend-postgres-quiz-1 psql -U quiz_user -d quiz_db < migrations/seeds/01_seed_geography_data.sql

# 6. Lancer le serveur
cargo run
```

Le serveur démarre sur `http://localhost:8080`

Voir [SETUP.md](docs/SETUP.md) pour le guide complet.


## 🧪 Tests

### **Démarrer la Base de Données de Test**

```bash
# Méthode 1 : Avec Make
make db-up

# Méthode 2 : Avec Docker Compose
docker-compose -f ../docker-compose.test.yml up -d

# Vérifier que la DB est démarrée
docker ps
```

**Connection String** : `postgresql://quiz_user:quiz_test@localhost:5433/quiz_db_test`

### **Lancer les Tests**

```bash
# Tous les tests
make test

# Tests avec démarrage auto de la DB
make test-db

# Tests API seulement
make test-api

# Tests unitaires seulement
make test-unit

# Un test spécifique
make test-one TEST=test_health_endpoint

# Avec logs détaillés
cargo test -- --nocapture
```

### **Templates de Tests Disponibles**

Le projet contient 4 templates de tests que tu peux copier/adapter :

1. **`tests/api_health_test.rs`** - Tests simples (health check)
2. **`tests/api_quizzes_test.rs`** - Tests CRUD complets
3. **`tests/api_sessions_test.rs`** - Tests de workflow
4. **`tests/api_answers_test.rs`** - Tests de logique métier

#### **Comment utiliser un template ?**

```bash
# 1. Copier un template
cp tests/api_health_test.rs tests/api_mon_endpoint_test.rs

# 2. Adapter le contenu
# - Remplacer les URLs
# - Adapter les JSON
# - Ajouter tes assertions

# 3. Lancer ton nouveau test
cargo test api_mon_endpoint
```

---

## 📊 Code Coverage

### **Installer cargo-llvm-cov**

```bash
cargo install cargo-llvm-cov
```

### **Générer le Coverage**

```bash
# Coverage HTML (s'ouvre dans le navigateur)
make coverage

# Résumé du coverage
make coverage-summary

# Générer JSON pour Codecov
make coverage-json
```

### **Objectif de Coverage**

🎯 **Objectif : 85% minimum**

Le coverage actuel se trouve dans le rapport HTML généré.

---

## 🎨 Formatage du Code

### **Option 1 : Avec Make**

```bash
# Formater le code
make fmt

# Vérifier le formatage
make check

# Linter (Clippy)
make clippy

# Tout à la fois
make lint
```

### **Option 2 : Script Standalone**

Puisque tu n'as pas accès au dossier `.git` dans ton IDE :

```bash
# Linux/Mac
./scripts/format-all.sh

# Windows PowerShell
.\scripts\format-all.ps1
```

### **Option 3 : Configuration IDE (VSCode)**

Créer `.vscode/settings.json` :

```json
{
  "editor.formatOnSave": true,
  "rust-analyzer.rustfmt.rangeFormatting.enable": true,
  "[rust]": {
    "editor.defaultFormatter": "rust-lang.rust-analyzer"
  }
}
```



## 🔄 GitHub Actions

### **Workflows Disponibles**

Le projet contient 3 workflows :

#### **1. Format (Automatique)**
- **Trigger** : Push sur `main` ou `develop`
- **Durée** : ~30 secondes
- **Actions** : Vérifie que le code est formaté

#### **2. Tests (Manuel)**
- **Trigger** : Manuel (workflow_dispatch)
- **Durée** : ~2-3 minutes
- **Actions** : Lance tous les tests avec PostgreSQL

**Comment lancer** :
1. Aller sur GitHub → **Actions** tab
2. Cliquer sur "**Backend Tests (Manual)**"
3. Cliquer "**Run workflow**" (bouton à droite)
4. Choisir la branche (main/develop)
5. Choisir le type de test (all/unit/api)
6. Cliquer "**Run workflow**" (bouton vert)

#### **3. Coverage (Manuel)**
- **Trigger** : Manuel (workflow_dispatch)
- **Durée** : ~3-4 minutes
- **Actions** : Génère rapport de coverage

**Comment lancer** : Même processus que Tests

**Récupérer le rapport** :
1. Aller dans l'exécution du workflow
2. Scroll en bas → **Artifacts**
3. Télécharger `coverage-report`
4. Ouvrir `index.html` dans un navigateur

---

## ☸️ Kubernetes Local

### **Setup Docker Desktop**

1. **Activer Kubernetes**
    - Docker Desktop → Settings → Kubernetes
    - Cocher "Enable Kubernetes"
    - Apply & Restart

2. **Vérifier**
   ```bash
   kubectl version
   kubectl get nodes
   ```

### **Déployer le Backend**

```bash
# 1. Créer le namespace
kubectl apply -f k8s/local/00-00_namespace.yaml

# 2. Déployer PostgreSQL
kubectl apply -f k8s/local/01-postgres.yaml

# 3. Attendre que PostgreSQL soit prêt
kubectl wait --for=condition=ready pod -l app=postgres -n quiz-app --timeout=60s

# 4. Déployer le backend
kubectl apply -f k8s/local/02-backend-deployment.yaml
kubectl apply -f k8s/local/03-backend-service.yaml

# 5. Configurer l'ingress
kubectl apply -f k8s/local/04-ingress.yaml
```

### **Vérifier le Déploiement**

```bash
# Voir les pods
kubectl get pods -n quiz-app

# Voir les services
kubectl get svc -n quiz-app

# Voir les logs
kubectl logs -f deployment/quiz-backend -n quiz-app

# Tester l'API
curl http://localhost/health
```

### **Nettoyer**

```bash
# Tout supprimer
kubectl delete namespace quiz-app
```

---

## 📝 Commandes Utiles

### **Make (Recommandé)**

```bash
make help           # Afficher toutes les commandes
make dev            # Setup environnement de dev
make ci             # Workflow CI complet
make clean-all      # Nettoyage complet
```

### **Cargo**

```bash
cargo build                    # Compiler
cargo run                      # Lancer le serveur
cargo test                     # Lancer les tests
cargo fmt                      # Formater
cargo clippy                   # Linter
cargo clean                    # Nettoyer
```

### **Docker**

```bash
# DB test
docker-compose -f ../docker-compose.test.yml up -d
docker-compose -f ../docker-compose.test.yml down
docker-compose -f ../docker-compose.test.yml logs -f

# Se connecter à la DB
docker exec -it quiz-postgres-test psql -U quiz_user -d quiz_db_test
```

### **Kubernetes**

```bash
kubectl get pods -n quiz-app              # Lister pods
kubectl logs -f <pod-name> -n quiz-app    # Logs
kubectl describe pod <pod-name> -n quiz-app  # Détails
kubectl exec -it <pod-name> -n quiz-app -- sh  # Shell dans le pod
```

---


## 📖 Documentation

- 📘 [Architecture & Plugins](docs/ARCHITECTURE.md)
- 📗 [API REST Documentation](docs/API.md)
- 📙 [Guide d'installation](docs/SETUP.md)
- 📕 [Guide développeur](docs/DEVELOPMENT.md)
- 📔 [Créer un plugin](docs/PLUGIN_GUIDE.md)
- 📓 [Base de données](docs/DATABASE.md)




## 🔌 Créer un Nouveau Plugin
```rust
use crate::plugins::{QuizPlugin, ValidationResult};

pub struct MyPlugin;

#[async_trait]
impl QuizPlugin for MyPlugin {
    fn domain_name(&self) -> &str { "my_domain" }
    
    async fn validate_answer(&self, ...) -> Result {
        // Votre logique de validation
    }
    
    fn calculate_score(&self, ...) -> i32 {
        // Votre logique de scoring
    }
}
```

Voir [PLUGIN_GUIDE.md](docs/PLUGIN_GUIDE.md) pour le guide complet.

## 🌐 API Endpoints

### Quiz
- `GET /api/v1/quizzes` - Liste des quiz actifs
- `GET /api/v1/quizzes/:id` - Détails d'un quiz
- `GET /api/v1/quizzes/:id/questions` - Questions d'un quiz

### Sessions
- `POST /api/v1/quizzes/:id/sessions` - Démarrer une session
- `GET /api/v1/sessions/:id` - Détails d'une session
- `POST /api/v1/sessions/:id/answers` - Soumettre une réponse
- `POST /api/v1/sessions/:id/finalize` - Finaliser une session

Voir [API.md](docs/API.md) pour la documentation complète avec exemples.

## 📊 Base de Données

### Tables principales

- `domains` - Domaines de quiz disponibles
- `quizzes` - Quiz configurés
- `questions` - Questions avec catégories
- `reponses` - Réponses possibles
- `sessions_quiz` - Sessions utilisateur
- `reponses_utilisateur` - Réponses soumises

Voir [DATABASE.md](docs/DATABASE.md) pour le schéma complet.

## 🔧 Technologies

- **Rust** - Langage système performant
- **Axum** - Framework web moderne
- **SQLx** - ORM async pour PostgreSQL
- **PostgreSQL** - Base de données relationnelle
- **Docker** - Containerisation
- **Serde** - Sérialisation JSON

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit (`git commit -m 'Add AmazingFeature'`)
4. Push (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 License

MIT License - voir [LICENSE](LICENSE)

## 👥 Auteurs

- Votre nom - [@votre_handle](https://github.com/votre_handle)

## 🙏 Remerciements

- Anthropic Claude pour l'assistance au développement
- La communauté Rust