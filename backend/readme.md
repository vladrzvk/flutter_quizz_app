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
```bash
# Lancer tous les tests
cargo test

# Tests avec logs
RUST_LOG=debug cargo test -- --nocapture

# Tests d'intégration uniquement
cargo test --test '*'
```

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