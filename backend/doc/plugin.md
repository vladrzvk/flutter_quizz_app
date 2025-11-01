# 🔌 Guide de Création de Plugin

Guide complet pour créer un nouveau plugin de domaine quiz.

## 📖 Introduction

Le système de plugins permet d'ajouter facilement de nouveaux domaines de quiz sans modifier le core de l'application.

**Exemples de plugins :**
- 🌍 **GeographyPlugin** (déjà implémenté)
- 🚗 **CodeRoutePlugin** (code de la route)
- 🎨 **CulturePlugin** (culture générale)
- 🔬 **SciencePlugin** (sciences)

---

## 🎯 Ce que fait un Plugin

Un plugin est responsable de :

1. **Validation des réponses** → Est-ce correct ?
2. **Calcul du score** → Combien de points ?
3. **Messages personnalisés** → Badges, feedback

---

## 📋 Prérequis

- Comprendre [l'architecture](ARCHITECTURE.md)
- Avoir le projet installé ([SETUP.md](SETUP.md))
- Connaître les bases de Rust et async/await

---

## 🚀 Créer un Plugin : Étape par Étape

### Exemple : CodeRoutePlugin

Nous allons créer un plugin pour des quiz de code de la route.

---

### ÉTAPE 1 : Créer la Structure
```bash
cd backend/quiz_core_service/src/plugins
mkdir code_route
touch code_route/mod.rs
touch code_route/code_route_plugin.rs
```

**Structure :**
```
plugins/
├── mod.rs
├── plugin_trait.rs
├── registry.rs
├── geography/
│   ├── mod.rs
│   └── geography_plugin.rs
└── code_route/              # ✨ NOUVEAU
    ├── mod.rs
    └── code_route_plugin.rs
```

---

### ÉTAPE 2 : Définir le Module

**`plugins/code_route/mod.rs` :**
```rust
mod code_route_plugin;

pub use code_route_plugin::CodeRoutePlugin;
```

---

### ÉTAPE 3 : Implémenter le Plugin

**`plugins/code_route/code_route_plugin.rs` :**
```rust
use async_trait::async_trait;
use shared::AppError;
use sqlx::PgPool;

use crate::{
    dto::session_dto::SubmitAnswerRequest,
    models::Question,
    plugins::{QuizPlugin, ValidationResult},
};

/// Plugin pour le domaine Code de la Route
pub struct CodeRoutePlugin;

#[async_trait]
impl QuizPlugin for CodeRoutePlugin {
    /// Nom du domaine (doit correspondre à la colonne `domain` en DB)
    fn domain_name(&self) -> &str {
        "code_route"
    }

    /// Nom d'affichage
    fn display_name(&self) -> &str {
        "Code de la Route"
    }

    /// Description
    fn description(&self) -> &str {
        "Quiz sur le code de la route : panneaux, priorités, règles"
    }

    /// Validation des réponses
    async fn validate_answer(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        match question.type_question.as_str() {
            "qcm" => self.validate_qcm(pool, question, answer).await,
            "vrai_faux" => self.validate_vrai_faux(pool, question, answer).await,
            "saisie_texte" => self.validate_saisie_texte(pool, question, answer).await,
            
            // Type spécifique au code de la route
            "reconnaissance_panneau" => {
                self.validate_reconnaissance_panneau(pool, question, answer).await
            }
            
            _ => Err(AppError::BadRequest(
                format!("Type '{}' non supporté pour le code de la route", question.type_question)
            )),
        }
    }

    /// Calcul du score avec bonus spécifiques
    fn calculate_score(
        &self,
        base_points: i32,
        validation: &ValidationResult,
        time_spent: i32,
        time_limit: Option<i32>,
        streak_count: i32,
    ) -> i32 {
        if !validation.is_correct && validation.partial_score.is_none() {
            return 0;
        }

        let mut points = base_points as f32;

        // Score partiel si applicable
        if let Some(partial) = validation.partial_score {
            points *= partial;
        }

        // 🚗 Bonus vitesse plus strict pour le code de la route
        // (sécurité routière = rapidité de réaction)
        if let Some(limit) = time_limit {
            let ratio = time_spent as f32 / limit as f32;
            if ratio < 0.2 {
                points *= 1.8; // +80% si très très rapide
            } else if ratio < 0.4 {
                points *= 1.5; // +50% si très rapide
            } else if ratio < 0.6 {
                points *= 1.2; // +20% si rapide
            } else if ratio > 0.9 {
                points *= 0.5; // -50% si trop lent (danger !)
            }
        }

        // Bonus streak (connaissances solides)
        if streak_count >= 5 {
            let streak_bonus = ((streak_count - 4) * 15).min(60) as f32 / 100.0;
            points += base_points as f32 * streak_bonus;
        }

        points.round() as i32
    }

    /// Messages personnalisés
    fn speed_badge(&self, time_spent: i32, time_limit: Option<i32>) -> Option<String> {
        time_limit.and_then(|limit| {
            let ratio = time_spent as f32 / limit as f32;
            if ratio < 0.2 {
                Some("🚀 Réflexes ultra-rapides !".to_string())
            } else if ratio < 0.4 {
                Some("⚡ Bons réflexes !".to_string())
            } else if ratio > 0.9 {
                Some("🐌 Attention, trop lent sur la route !".to_string())
            } else {
                None
            }
        })
    }

    /// Seed des données (optionnel)
    async fn seed_data(&self, _pool: &PgPool) -> Result<(), AppError> {
        tracing::info!("🚗 CodeRoutePlugin: seed data via SQL scripts");
        Ok(())
    }
}

// Méthodes privées spécifiques
impl CodeRoutePlugin {
    /// Validation reconnaissance de panneau
    async fn validate_reconnaissance_panneau(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        // Logique spécifique à la reconnaissance de panneaux
        // Par exemple : vérifier que le panneau sélectionné est correct
        
        let reponse_id = answer
            .reponse_id
            .ok_or_else(|| AppError::BadRequest("reponse_id requis pour reconnaissance_panneau".to_string()))?;

        let is_correct: bool = sqlx::query_scalar(
            "SELECT is_correct FROM reponses WHERE id = $1 AND question_id = $2"
        )
        .bind(reponse_id)
        .bind(question.id)
        .fetch_one(pool)
        .await?;

        if is_correct {
            Ok(ValidationResult::correct("Panneau correct !")
                .with_explanation(
                    question.explanation.clone().unwrap_or_default()
                ))
        } else {
            Ok(ValidationResult::incorrect("Panneau incorrect")
                .with_explanation(
                    question.explanation.clone().unwrap_or_default()
                ))
        }
    }
}
```

---

### ÉTAPE 4 : Enregistrer le Plugin

**Modifier `plugins/mod.rs` :**
```rust
mod plugin_trait;
mod registry;
mod geography;
mod code_route;  // ✅ AJOUTER

pub use plugin_trait::{QuizPlugin, ValidationResult};
pub use registry::PluginRegistry;
pub use geography::GeographyPlugin;
pub use code_route::CodeRoutePlugin;  // ✅ AJOUTER
```

---

### ÉTAPE 5 : Activer dans main.rs

**Modifier `main.rs` :**
```rust
use plugins::{PluginRegistry, GeographyPlugin, CodeRoutePlugin};  // ✅ AJOUTER

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // ... config, database ...

    // Plugin Registry
    tracing::info!("🔌 Initializing plugin registry...");
    let mut plugin_registry = PluginRegistry::new();
    
    plugin_registry.register(Arc::new(GeographyPlugin));
    plugin_registry.register(Arc::new(CodeRoutePlugin));  // ✅ AJOUTER
    
    tracing::info!(
        "✅ Plugin registry initialized with {} plugins",
        plugin_registry.count()
    );

    // ... reste du code ...
}
```

---

### ÉTAPE 6 : Créer les Données

**Migration SQL : `migrations/seeds/02_seed_code_route_data.sql` :**
```sql
-- Ajouter le domaine
INSERT INTO domains (name, display_name, description, config) VALUES
    ('code_route', 'Code de la Route', 'Quiz sur le code de la route français', '{"icon": "🚗", "color": "#FF5722"}'::jsonb)
    ON CONFLICT (name) DO NOTHING;

-- Créer un quiz
INSERT INTO quizzes (
    id,
    domain,
    titre,
    description,
    niveau_difficulte,
    version_app,
    scope,
    mode,
    nb_questions,
    is_active
) VALUES (
    '00000000-0000-0000-0000-000000000002'::uuid,
    'code_route',
    'Panneaux Routiers - Niveau 1',
    'Quiz sur la signalisation routière française',
    'facile',
    '1.0.0',
    'france',
    'entrainement',
    5,
    true
) ON CONFLICT (id) DO NOTHING;

-- Question 1 : QCM Panneau STOP
INSERT INTO questions (
    id,
    quiz_id,
    ordre,
    type_question,
    question_data,
    category,
    subcategory,
    media_url,
    points,
    temps_limite_sec,
    explanation
) VALUES (
    '00000000-0000-0000-0002-000000000001'::uuid,
    '00000000-0000-0000-0000-000000000002'::uuid,
    1,
    'reconnaissance_panneau',
    '{"text": "Que signifie ce panneau ?", "image": "/assets/panneau_stop.png"}'::jsonb,
    'panneaux',
    'obligation',
    'https://example.com/panneau_stop.png',
    10,
    8,
    'Le panneau STOP impose un arrêt complet à toute intersection'
) ON CONFLICT (id) DO NOTHING;

-- Réponses Question 1
INSERT INTO reponses (question_id, valeur, is_correct, ordre) VALUES
    ('00000000-0000-0000-0002-000000000001'::uuid, 'Arrêt obligatoire', true, 1),
    ('00000000-0000-0000-0002-000000000001'::uuid, 'Cédez le passage', false, 2),
    ('00000000-0000-0000-0002-000000000001'::uuid, 'Sens interdit', false, 3),
    ('00000000-0000-0000-0002-000000000001'::uuid, 'Priorité à droite', false, 4)
ON CONFLICT DO NOTHING;

-- ... ajouter plus de questions ...
```

**Appliquer le seed :**
```powershell
docker cp migrations/seeds/02_seed_code_route_data.sql backend-postgres-quiz-1:/tmp/seed_code_route.sql
docker exec -it backend-postgres-quiz-1 psql -U quiz_user -d quiz_db -f /tmp/seed_code_route.sql
```

---

### ÉTAPE 7 : Compiler et Tester
```bash
cargo build
cargo run
```

**Logs attendus :**
```
📝 Registering quiz plugin domain=geography display_name=Géographie
📝 Registering quiz plugin domain=code_route display_name=Code de la Route
✅ Plugin registry initialized with 2 plugins
```

**Tester l'API :**
```bash
curl http://localhost:8080/api/v1/quizzes
```

Vous devriez voir les 2 quiz (géographie + code de la route) !

---

## 🎨 Personnalisation Avancée

### Ajouter un Type de Question Custom
```rust
// Dans code_route_plugin.rs

async fn validate_answer(
    &self,
    pool: &PgPool,
    question: &Question,
    answer: &SubmitAnswerRequest,
) -> Result<ValidationResult, AppError> {
    match question.type_question.as_str() {
        // ... types standards ...
        
        // ✨ Type personnalisé
        "scenario_routier" => {
            self.validate_scenario(pool, question, answer).await
        }
        
        _ => Err(AppError::BadRequest(format!(
            "Type '{}' non supporté", question.type_question
        ))),
    }
}

async fn validate_scenario(
    &self,
    pool: &PgPool,
    question: &Question,
    answer: &SubmitAnswerRequest,
) -> Result<ValidationResult, AppError> {
    // Votre logique personnalisée
    // Par exemple : valider une séquence d'actions
    
    let actions = answer.valeur_saisie
        .as_ref()
        .ok_or_else(|| AppError::BadRequest("Actions requises".to_string()))?;
    
    // Parser et valider les actions
    let expected = question.question_data.get("expected_sequence")
        .and_then(|v| v.as_str())
        .ok_or_else(|| AppError::InternalError("Séquence attendue manquante".to_string()))?;
    
    if actions == expected {
        Ok(ValidationResult::correct("Séquence correcte !"))
    } else {
        Ok(ValidationResult::incorrect("Séquence incorrecte")
            .with_explanation(format!("La bonne séquence était : {}", expected)))
    }
}
```

---

### Score Partiel
```rust
fn calculate_score(
    &self,
    base_points: i32,
    validation: &ValidationResult,
    time_spent: i32,
    time_limit: Option<i32>,
    streak_count: i32,
) -> i32 {
    // Score partiel pour réponses incomplètes
    let mut points = base_points as f32;
    
    if let Some(partial) = validation.partial_score {
        points *= partial;  // Ex: 0.5 pour 50% correct
    }
    
    // ... reste du calcul ...
}
```

**Utilisation :**
```rust
// Dans validate_answer
if partially_correct {
    return Ok(ValidationResult {
        is_correct: false,
        message: "Partiellement correct".to_string(),
        partial_score: Some(0.5),  // 50% des points
        explanation: Some("2 sur 4 éléments corrects".to_string()),
    });
}
```

---

### Badges Personnalisés
```rust
fn speed_badge(&self, time_spent: i32, time_limit: Option<i32>) -> Option<String> {
    time_limit.and_then(|limit| {
        let ratio = time_spent as f32 / limit as f32;
        
        // Badges créatifs
        if ratio < 0.15 {
            Some("🏎️ Pilote de F1 !".to_string())
        } else if ratio < 0.3 {
            Some("🚗 Conduite sportive !".to_string())
        } else if ratio < 0.5 {
            Some("🚙 Conduite fluide".to_string())
        } else if ratio < 0.7 {
            Some("🚕 Conduite prudente".to_string())
        } else if ratio > 0.9 {
            Some("🐌 Attention aux ralentissements !".to_string())
        } else {
            None
        }
    })
}
```

---

## ✅ Checklist de Création de Plugin

- [ ] Créer le dossier `plugins/<nom_plugin>/`
- [ ] Créer `mod.rs` et `<nom_plugin>_plugin.rs`
- [ ] Implémenter le trait `QuizPlugin`
- [ ] Ajouter dans `plugins/mod.rs`
- [ ] Enregistrer dans `main.rs`
- [ ] Créer la migration de domaine
- [ ] Créer le seed de données
- [ ] Compiler sans erreurs
- [ ] Tester l'API
- [ ] Vérifier les logs (X plugins enregistrés)
- [ ] Documenter le plugin

---

## 🧪 Tester Votre Plugin

### Test Manuel
```bash
# 1. Lister les quiz
curl http://localhost:8080/api/v1/quizzes

# 2. Démarrer session
curl -X POST http://localhost:8080/api/v1/quizzes/<QUIZ_ID>/sessions \
  -H "Content-Type: application/json" \
  -d '{"user_id":"11111111-1111-1111-1111-111111111111"}'

# 3. Soumettre réponse
curl -X POST http://localhost:8080/api/v1/sessions/<SESSION_ID>/answers \
  -H "Content-Type: application/json" \
  -d '{"question_id":"...","reponse_id":"...","temps_reponse_sec":5}'
```

### Test Automatisé

**Créer `tests/plugins/code_route_test.rs` :**
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_code_route_plugin_validate_qcm() {
        let plugin = CodeRoutePlugin;
        
        // Setup test data
        let pool = setup_test_db().await;
        let question = create_test_question(&pool).await;
        let answer = SubmitAnswerRequest {
            question_id: question.id,
            reponse_id: Some(correct_answer_id()),
            temps_reponse_sec: 5,
            valeur_saisie: None,
        };
        
        // Test validation
        let result = plugin.validate_answer(&pool, &question, &answer).await;
        
        assert!(result.is_ok());
        assert!(result.unwrap().is_correct);
    }

    #[test]
    fn test_code_route_plugin_score_calculation() {
        let plugin = CodeRoutePlugin;
        
        let score = plugin.calculate_score(
            10,    // base_points
            &ValidationResult::correct("Test"),
            3,     // time_spent
            Some(15), // time_limit
            2,     // streak
        );
        
        // 3/15 = 0.2 ratio → bonus 1.8x = 18 points
        assert_eq!(score, 18);
    }
}
```

---

## 📚 Ressources

- [Trait QuizPlugin](../src/plugins/plugin_trait.rs)
- [GeographyPlugin (exemple)](../src/plugins/geography/geography_plugin.rs)
- [Architecture complète](ARCHITECTURE.md)
- [API Documentation](API.md)

---

## 🤝 Contribuer Votre Plugin

1. Fork le projet
2. Créer votre plugin dans une branche
3. Ajouter tests + documentation
4. Ouvrir une Pull Request
5. Votre plugin sera reviewé et mergé !

**Idées de plugins bienvenues :**
- 🎨 Culture générale
- 🔬 Sciences
- 📚 Histoire
- 🎵 Musique
- ⚽ Sport
- 🍳 Gastronomie