# 🏗️ Architecture du Système de Quiz

## Vue d'ensemble

Le système utilise une **Clean Architecture** avec un **système de plugins** pour supporter multiple domaines de quiz.

## Principes d'Architecture

### 1. Séparation des Responsabilités
```
┌─────────────────────────────────────────────┐
│           HTTP Layer (Axum)                 │
│  handlers/ - Contrôleurs REST               │
└─────────────┬───────────────────────────────┘
              │
┌─────────────▼───────────────────────────────┐
│         Business Logic Layer                │
│  services/ - Logique métier                 │
│  plugins/ - Validation & Scoring            │
└─────────────┬───────────────────────────────┘
              │
┌─────────────▼───────────────────────────────┐
│          Data Access Layer                  │
│  repositories/ - Accès DB                   │
└─────────────┬───────────────────────────────┘
              │
┌─────────────▼───────────────────────────────┐
│           Database (PostgreSQL)             │
└─────────────────────────────────────────────┘
```

### 2. Flux de Données
```
Request → Handler → Service → Plugin → Repository → Database
                       ↓
Response ← Handler ← Service ← Plugin ← Repository ← Database
```

## Système de Plugins

### Architecture des Plugins
```rust
// Trait générique pour tous les plugins
pub trait QuizPlugin: Send + Sync {
    fn domain_name(&self) -> &str;
    fn display_name(&self) -> &str;
    fn description(&self) -> &str;
    
    async fn validate_answer(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError>;
    
    fn calculate_score(
        &self,
        base_points: i32,
        validation: &ValidationResult,
        time_spent: i32,
        time_limit: Option<i32>,
        streak_count: i32,
    ) -> i32;
    
    fn speed_badge(&self, time_spent: i32, time_limit: Option<i32>) -> Option<String>;
}
```

### PluginRegistry

Le `PluginRegistry` gère tous les plugins disponibles :
```rust
pub struct PluginRegistry {
    plugins: HashMap<String, Arc<dyn QuizPlugin>>,
}

impl PluginRegistry {
    pub fn register(&mut self, plugin: Arc<dyn QuizPlugin>) {
        let domain = plugin.domain_name().to_string();
        self.plugins.insert(domain, plugin);
    }
    
    pub fn get(&self, domain: &str) -> Option<Arc<dyn QuizPlugin>> {
        self.plugins.get(domain).cloned()
    }
}
```

### Enregistrement des Plugins
```rust
// main.rs
let mut plugin_registry = PluginRegistry::new();
plugin_registry.register(Arc::new(GeographyPlugin));
plugin_registry.register(Arc::new(CodeRoutePlugin)); // Futur
```

## Modèles de Données

### Domain Entity (models/)
```rust
pub struct Quiz {
    pub id: Uuid,
    pub domain: String,        // Lien vers le plugin
    pub titre: String,
    pub scope: String,         // france, europe, monde
    pub category: Option<String>,
    // ...
}

pub struct Question {
    pub id: Uuid,
    pub quiz_id: Uuid,
    pub type_question: String,  // qcm, vrai_faux, saisie_texte
    pub category: Option<String>,
    pub subcategory: Option<String>,
    // ...
}
```

### DTOs (dto/)

Les DTOs exposent uniquement les données nécessaires au client :
```rust
pub struct QuestionWithReponses {
    pub id: Uuid,
    pub question_data: Value,
    pub reponses: Vec<ReponseDto>, // Sans is_correct pour QCM
    // ...
}
```

## Flow de Validation

### 1. Soumission d'une réponse
```
Client → POST /sessions/{id}/answers
         ↓
Handler (session_handler.rs)
         ↓
Service (session_service.rs)
         ├─ Récupère la session
         ├─ Récupère la question
         ├─ Récupère le quiz pour le domaine
         ↓
Plugin Registry
         ├─ Sélectionne le bon plugin (geography, code_route, etc.)
         ↓
Plugin (geography_plugin.rs)
         ├─ validate_answer() → ValidationResult
         ├─ calculate_score() → points avec bonus
         ↓
Repository (session_repo.rs)
         ├─ Enregistre la réponse
         ├─ Met à jour le score
         ↓
Response → ReponseUtilisateur
```

### 2. Calcul du Score
```rust
// 1. Score de base
let base_points = question.points; // ex: 10

// 2. Bonus vitesse
let speed_multiplier = if ratio < 0.3 { 1.5 }  // +50%
                       else if ratio < 0.5 { 1.25 } // +25%
                       else if ratio > 0.9 { 0.75 } // -25%
                       else { 1.0 };

// 3. Bonus streak
let streak_bonus = ((streak_count - 2) * 10).min(50) as f32 / 100.0;

// 4. Score final
let final_score = (base_points * speed_multiplier) + (base_points * streak_bonus);
```

## Patterns Utilisés

### 1. Strategy Pattern (Plugins)

Chaque plugin implémente sa propre stratégie de validation et scoring.

### 2. Repository Pattern

Abstraction de l'accès aux données.

### 3. Service Layer Pattern

Logique métier centralisée.

### 4. DTO Pattern

Séparation entre entités DB et objets exposés.

## Extensibilité

### Ajouter un Nouveau Domaine

1. **Créer le plugin**
```rust
// src/plugins/code_route/mod.rs
pub struct CodeRoutePlugin;

#[async_trait]
impl QuizPlugin for CodeRoutePlugin {
    fn domain_name(&self) -> &str { "code_route" }
    // Implémenter les méthodes...
}
```

2. **Enregistrer dans main.rs**
```rust
plugin_registry.register(Arc::new(CodeRoutePlugin));
```

3. **Créer les données**
```sql
INSERT INTO domains (name, display_name) 
VALUES ('code_route', 'Code de la Route');

INSERT INTO quizzes (domain, titre, ...) 
VALUES ('code_route', 'Panneaux routiers', ...);
```

**C'est tout !** Le système gère automatiquement le nouveau domaine.

## Sécurité

### 1. Validation côté serveur

Toute validation se fait côté serveur via les plugins.

### 2. Protection des réponses

`is_correct` n'est **JAMAIS** exposé au client pour les QCM.

### 3. Contraintes DB
```sql
UNIQUE(session_id, question_id) -- Une seule réponse par question
```

### 4. Types stricts

Rust garantit la sécurité des types à la compilation.

## Performance

### 1. Connection Pooling

SQLx gère un pool de connexions PostgreSQL.

### 2. Async/Await

Toutes les opérations I/O sont asynchrones.

### 3. Arc pour les Plugins

Les plugins sont partagés via `Arc<dyn QuizPlugin>`.

### 4. Index DB

Index sur toutes les colonnes fréquemment requêtées.

## Tests

### Structure des tests
```
tests/
├── integration/
│   ├── quiz_tests.rs
│   ├── session_tests.rs
│   └── plugin_tests.rs
└── unit/
    ├── services/
    └── repositories/
```

### Exemple de test
```rust
#[tokio::test]
async fn test_submit_correct_answer() {
    let pool = setup_test_db().await;
    let registry = create_test_registry();
    
    let session = start_test_session(&pool).await;
    let answer = SubmitAnswerRequest {
        question_id: test_question_id(),
        reponse_id: Some(correct_answer_id()),
        temps_reponse_sec: 5,
    };
    
    let result = SessionService::submit_answer(
        &pool, &registry, session.id, answer
    ).await;
    
    assert!(result.is_ok());
    assert!(result.unwrap().is_correct);
}
```