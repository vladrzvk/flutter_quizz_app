# 👨‍💻 Guide du Développeur

Guide complet pour contribuer au projet et développer de nouvelles fonctionnalités.

## 🎯 Philosophie du Projet

### Principes

1. **Clean Architecture** - Séparation claire des responsabilités
2. **Extensibilité** - Facile d'ajouter de nouveaux domaines via plugins
3. **Type Safety** - Rust garantit la sécurité des types
4. **Performance** - Async/await pour la scalabilité
5. **Maintenabilité** - Code documenté et testé

---

## 🏗️ Structure du Projet
```
backend/
├── quiz_core_service/           # Service principal
│   ├── src/
│   │   ├── main.rs              # Point d'entrée
│   │   ├── config.rs            # Configuration
│   │   ├── models/              # Entités métier
│   │   │   ├── mod.rs
│   │   │   ├── quiz.rs
│   │   │   ├── question.rs
│   │   │   ├── reponse.rs
│   │   │   └── session.rs
│   │   ├── dto/                 # Data Transfer Objects
│   │   │   ├── mod.rs
│   │   │   ├── quiz_dto.rs
│   │   │   ├── question_dto.rs
│   │   │   └── session_dto.rs
│   │   ├── repositories/        # Accès données
│   │   │   ├── mod.rs
│   │   │   ├── quiz_repo.rs
│   │   │   ├── question_repo.rs
│   │   │   ├── reponse_repo.rs
│   │   │   └── session_repo.rs
│   │   ├── services/            # Logique métier
│   │   │   ├── mod.rs
│   │   │   ├── quiz_service.rs
│   │   │   ├── question_service.rs
│   │   │   └── session_service.rs
│   │   ├── handlers/            # Contrôleurs HTTP
│   │   │   ├── mod.rs
│   │   │   ├── quiz_handler.rs
│   │   │   ├── question_handler.rs
│   │   │   └── session_handler.rs
│   │   ├── routes/              # Routes API
│   │   │   └── mod.rs
│   │   └── plugins/             # Système de plugins
│   │       ├── mod.rs
│   │       ├── plugin_trait.rs
│   │       ├── registry.rs
│   │       └── geography/
│   │           ├── mod.rs
│   │           └── geography_plugin.rs
│   ├── migrations/              # Migrations SQL
│   │   ├── 20251030000001_init_schema.sql
│   │   └── seeds/
│   │       └── 01_seed_geography_data.sql
│   ├── tests/                   # Tests
│   │   ├── integration/
│   │   └── unit/
│   ├── Cargo.toml
│   └── .env
├── shared/                      # Code partagé
│   ├── src/
│   │   └── error.rs             # Gestion d'erreurs
│   └── Cargo.toml
├── docker-compose.yml
└── docs/                        # Documentation
```

---

## 🚀 Workflow de Développement

### 1. Branching Strategy
```bash
main                # Production
  ├─ develop        # Développement
  │   ├─ feature/quiz-filtering
  │   ├─ feature/new-plugin
  │   └─ bugfix/scoring-issue
  └─ hotfix/critical-bug
```

**Conventions de nommage :**
- `feature/` - Nouvelles fonctionnalités
- `bugfix/` - Corrections de bugs
- `hotfix/` - Corrections urgentes pour production
- `refactor/` - Refactoring de code
- `docs/` - Documentation

---

### 2. Développer une Nouvelle Fonctionnalité

#### A. Créer une Branche
```bash
git checkout develop
git pull
git checkout -b feature/ma-fonctionnalite
```

#### B. Développer
```bash
# Lancer en mode watch
cargo watch -x run

# Ou avec logs détaillés
RUST_LOG=debug cargo watch -x run
```

#### C. Tester
```bash
# Tests unitaires
cargo test

# Tests d'intégration
cargo test --test '*'

# Test spécifique
cargo test test_submit_answer

# Avec logs
RUST_LOG=debug cargo test -- --nocapture
```

#### D. Formatter & Lint
```bash
# Formatter
cargo fmt

# Linter
cargo clippy

# Fix automatique
cargo clippy --fix
```

#### E. Commit
```bash
git add .
git commit -m "feat: add quiz filtering by category"
```

**Conventions de commit :**
- `feat:` - Nouvelle fonctionnalité
- `fix:` - Correction de bug
- `docs:` - Documentation
- `refactor:` - Refactoring
- `test:` - Tests
- `chore:` - Maintenance

#### F. Push & Pull Request
```bash
git push origin feature/ma-fonctionnalite
```

Puis créer une Pull Request sur GitHub.

---

## 🧪 Tests

### Structure des Tests
```
tests/
├── integration/
│   ├── quiz_api_test.rs
│   ├── session_api_test.rs
│   └── plugin_test.rs
└── unit/
    ├── services/
    │   ├── quiz_service_test.rs
    │   └── session_service_test.rs
    └── plugins/
        └── geography_plugin_test.rs
```

---

### Test Unitaire

**Exemple : `tests/unit/services/quiz_service_test.rs`**
```rust
#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::PgPool;

    async fn setup_test_db() -> PgPool {
        let pool = PgPool::connect("postgresql://test_user:test@localhost:5433/test_db")
            .await
            .expect("Failed to connect to test DB");
        
        sqlx::migrate!("./migrations")
            .run(&pool)
            .await
            .expect("Failed to run migrations");
        
        pool
    }

    #[tokio::test]
    async fn test_get_active_quizzes() {
        let pool = setup_test_db().await;
        
        // Arrange
        seed_test_data(&pool).await;
        
        // Act
        let quizzes = QuizService::get_all_active(&pool).await.unwrap();
        
        // Assert
        assert_eq!(quizzes.len(), 1);
        assert_eq!(quizzes[0].domain, "geography");
        
        // Cleanup
        cleanup_test_db(&pool).await;
    }

    #[tokio::test]
    async fn test_create_quiz() {
        let pool = setup_test_db().await;
        
        let request = CreateQuizRequest {
            domain: "geography".to_string(),
            titre: "Test Quiz".to_string(),
            // ... autres champs
        };
        
        let quiz = QuizService::create(&pool, request).await.unwrap();
        
        assert_eq!(quiz.titre, "Test Quiz");
        assert!(quiz.is_active);
    }
}
```

---

### Test d'Intégration

**Exemple : `tests/integration/quiz_api_test.rs`**
```rust
use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use tower::ServiceExt;

#[tokio::test]
async fn test_get_quizzes_endpoint() {
    let app = create_test_app().await;
    
    let response = app
        .oneshot(
            Request::builder()
                .uri("/api/v1/quizzes")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    
    assert_eq!(response.status(), StatusCode::OK);
    
    let body = hyper::body::to_bytes(response.into_body()).await.unwrap();
    let quizzes: Vec<Quiz> = serde_json::from_slice(&body).unwrap();
    
    assert!(quizzes.len() > 0);
}

#[tokio::test]
async fn test_start_session_endpoint() {
    let app = create_test_app().await;
    
    let body = serde_json::json!({
        "user_id": "11111111-1111-1111-1111-111111111111"
    });
    
    let response = app
        .oneshot(
            Request::builder()
                .method("POST")
                .uri("/api/v1/quizzes/00000000-0000-0000-0000-000000000001/sessions")
                .header("content-type", "application/json")
                .body(Body::from(serde_json::to_vec(&body).unwrap()))
                .unwrap(),
        )
        .await
        .unwrap();
    
    assert_eq!(response.status(), StatusCode::OK);
}
```

---

### Test de Plugin

**Exemple : `tests/unit/plugins/geography_plugin_test.rs`**
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_validate_qcm_correct_answer() {
        let plugin = GeographyPlugin;
        let pool = setup_test_db().await;
        
        let question = create_test_question(&pool, "qcm").await;
        let answer = SubmitAnswerRequest {
            question_id: question.id,
            reponse_id: Some(get_correct_answer_id(&pool, question.id).await),
            temps_reponse_sec: 5,
            valeur_saisie: None,
        };
        
        let result = plugin.validate_answer(&pool, &question, &answer).await;
        
        assert!(result.is_ok());
        assert!(result.unwrap().is_correct);
    }

    #[test]
    fn test_calculate_score_with_speed_bonus() {
        let plugin = GeographyPlugin;
        
        let score = plugin.calculate_score(
            10,    // base_points
            &ValidationResult::correct("Test"),
            4,     // time_spent (26% du temps)
            Some(15), // time_limit
            0,     // no streak
        );
        
        // Bonus vitesse : 4/15 = 0.26 → +50% = 15 points
        assert_eq!(score, 15);
    }

    #[test]
    fn test_calculate_score_with_streak() {
        let plugin = GeographyPlugin;
        
        let score = plugin.calculate_score(
            10,    // base_points
            &ValidationResult::correct("Test"),
            8,     // time_spent (normale, pas de bonus vitesse)
            Some(15),
            3,     // 3 bonnes consécutives
        );
        
        // Bonus streak : +10% = 11 points
        assert_eq!(score, 11);
    }
}
```

---

## 🔨 Outils de Développement

### Cargo Watch

Recompile automatiquement à chaque modification :
```bash
cargo install cargo-watch
cargo watch -x run
```

### Cargo Expand

Voir le code après expansion des macros :
```bash
cargo install cargo-expand
cargo expand
```

### SQLx Offline Mode

Compiler sans connexion DB :
```bash
cargo sqlx prepare
cargo build --features sqlx/offline
```

### Clippy (Linter)
```bash
cargo clippy -- -D warnings
```

### Rustfmt (Formatter)
```bash
cargo fmt -- --check  # Vérifier
cargo fmt             # Formatter
```

---

## 📊 Monitoring & Logging

### Niveaux de Log
```rust
use tracing::{debug, info, warn, error};

info!("Starting quiz session", session_id = %session_id);
debug!(score = score, "Score calculated");
warn!("Session timeout", session_id = %session_id);
error!(error = ?err, "Database error");
```

### Configuration

Dans `.env` :
```bash
RUST_LOG=info,quiz_service=debug,sqlx=info
```

**Niveaux :**
- `error` - Erreurs critiques
- `warn` - Avertissements
- `info` - Informations importantes
- `debug` - Debug détaillé
- `trace` - Tout

---

## 🐛 Debugging

### Avec VSCode

**`.vscode/launch.json` :**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "lldb",
      "request": "launch",
      "name": "Debug Quiz Service",
      "cargo": {
        "args": [
          "build",
          "--bin=quiz_core_service",
          "--package=quiz_core_service"
        ],
        "filter": {
          "name": "quiz_core_service",
          "kind": "bin"
        }
      },
      "args": [],
      "cwd": "${workspaceFolder}/backend/quiz_core_service"
    }
  ]
}
```

### Avec println! / dbg!
```rust
// Debug simple
println!("Score: {}", score);

// Debug avec structure
dbg!(&session);

// Debug conditionnel
#[cfg(debug_assertions)]
println!("Debug mode: {:?}", value);
```

---

## 📦 Dépendances

### Ajouter une Dépendance
```bash
cd quiz_core_service
cargo add nom_du_crate
```

**Exemple :**
```bash
cargo add serde --features derive
cargo add tokio --features full
```

### Mettre à Jour
```bash
cargo update
```

### Audit de Sécurité
```bash
cargo install cargo-audit
cargo audit
```

---

## 🔐 Bonnes Pratiques

### 1. Gestion d'Erreurs
```rust
// ✅ BON
pub async fn get_quiz(pool: &PgPool, id: Uuid) -> Result<Quiz, AppError> {
    QuizRepository::find_by_id(pool, id)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Quiz {} not found", id)))
}

// ❌ MAUVAIS
pub async fn get_quiz(pool: &PgPool, id: Uuid) -> Quiz {
    QuizRepository::find_by_id(pool, id).await.unwrap().unwrap()
}
```

### 2. Validation
```rust
// ✅ BON - Validation dans le service
pub async fn create_quiz(request: CreateQuizRequest) -> Result<Quiz, AppError> {
    if request.titre.is_empty() {
        return Err(AppError::BadRequest("Titre requis".to_string()));
    }
    // ...
}
```

### 3. Sécurité
```rust
// ✅ BON - Ne jamais exposer is_correct pour QCM
pub struct ReponseDto {
    pub id: Uuid,
    pub valeur: Option<String>,
    // is_correct est PRIVÉ
}

// ❌ MAUVAIS
pub struct ReponseDto {
    pub is_correct: bool,  // Le client peut tricher !
}
```

### 4. Performance
```rust
// ✅ BON - Utiliser les index
sqlx::query("SELECT * FROM questions WHERE quiz_id = $1")
    .bind(quiz_id)

// ❌ MAUVAIS - Scan complet
sqlx::query("SELECT * FROM questions WHERE quiz_id::TEXT = $1")
```

---

## 📝 Checklist PR

Avant de soumettre une Pull Request :

- [ ] Code compile sans warnings
- [ ] Tests passent (`cargo test`)
- [ ] Code formaté (`cargo fmt`)
- [ ] Clippy OK (`cargo clippy`)
- [ ] Documentation à jour
- [ ] Migration SQL ajoutée si nécessaire
- [ ] Tests ajoutés pour nouvelle feature
- [ ] Logs ajoutés aux points importants
- [ ] Pas de secrets dans le code
- [ ] CHANGELOG.md mis à jour

---

## 🎓 Ressources d'Apprentissage

### Rust

- [The Rust Book](https://doc.rust-lang.org/book/)
- [Rust by Example](https://doc.rust-lang.org/rust-by-example/)
- [Async Book](https://rust-lang.github.io/async-book/)

### Axum

- [Axum Documentation](https://docs.rs/axum/)
- [Axum Examples](https://github.com/tokio-rs/axum/tree/main/examples)

### SQLx

- [SQLx Documentation](https://docs.rs/sqlx/)
- [SQLx Guide](https://github.com/launchbadge/sqlx/blob/main/README.md)

### PostgreSQL

- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
- [PostgreSQL Performance](https://www.postgresql.org/docs/current/performance-tips.html)

---

## 🆘 Aide

- 📖 [Documentation](../README.md)
- 🐛 [Issues](https://github.com/votre-repo/quiz-app/issues)
- 💬 [Discussions](https://github.com/votre-repo/quiz-app/discussions)
- 📧 Email : dev@example.com