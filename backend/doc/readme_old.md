### SCHÉMA D'ARCHITECTURE BACKEND PLUG AND PLAY V0 : Vue d'ensemble : Comment tout s'articule

┌─────────────────────────────────────────────────────────────────────┐
│                          CLIENT (Flutter)                           │
└────────────────────────────────┬────────────────────────────────────┘
                                │
                   HTTP Request │ POST /api/v1/sessions/:id/answers
                                │ Body: { question_id, answer, time }
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         AXUM ROUTER                                 │
│  src/routes.rs                                                      │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Route: POST /sessions/:id/answers                             │ │
│  │   → Handler: submit_answer_handler                            │ │
│  │   → State: AppState (pool + plugin_registry)                  │ │
│  └───────────────────────────────────────────────────────────────┘ │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         HANDLER LAYER                               │
│  src/handlers/session_handler.rs                                    │
│                                                                     │
│  pub async fn submit_answer_handler(                                │
│      State(app_state): State<AppState>,  ← REÇOIT AppState          │
│      Path(session_id): Path<Uuid>,                                  │
│      Json(payload): Json<SubmitAnswerRequest>                       │
│  ) -> Result<...>                                                   │
│                                                                     │
│  1. Extraire pool et plugin_registry de app_state                   │
│  2. Appeler le SERVICE                                              │
│                                                                     │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         SERVICE LAYER                               │
│  src/services/session_service.rs                                    │
│                                                                     │
│  SessionService::submit_answer(                                     │
│      pool,                                                          │
│      plugin_registry,  ← REÇOIT le registry                         │
│      session_id,                                                    │
│      payload                                                        │
│  )                                                                  │
│                                                                     │
│  LOGIQUE MÉTIER:                                                    │
│  1. Récupérer la session                                            │
│  2. Récupérer le quiz                                               │
│  3. Récupérer le plugin du domaine → plugin_registry.get(domain)    │
│  4. Récupérer la question                                           │
│  5. VALIDER avec le plugin → plugin.validate_answer(...)            │
│  6. SCORER avec le plugin → plugin.calculate_score(...)             │
│  7. Sauvegarder la réponse                                          │
│                                                                     │
└───────────┬───────────────────────────────────┬─────────────────────┘
│                                   │
│ 3. Get Plugin                     │ 5. Validate
▼                                   ▼
┌───────────────────────────┐     ┌────────────────────────────────┐
│   PLUGIN REGISTRY         │     │   GEOGRAPHY PLUGIN             │
│   src/plugins/registry.rs │     │   geography_plugin/src/lib.rs  │
│                           │     │                                │
│  HashMap<String, Plugin>  │     │  impl QuizPlugin {             │
│  ┌─────────────────────┐  │     │    fn domain_name() -> "geo"   │
│  │ "geography" → Plugin│  │     │                                │
│  │ "code_route" → ...  │  │     │    async fn validate_answer()  │
│  └─────────────────────┘  │     │      match type_question {     │
│                           │     │        "qcm" → validate_qcm    │
│  registry.get("geography")│     │        "carte" → validate_map  │
│    → Arc<GeographyPlugin> │     │        ...                     │
│                           │     │      }                         │
└───────────────────────────┘     │                                │
                                  │    fn calculate_score()        │
                                  │      → bonus vitesse, streak   │
                                  └────────────────────────────────┘
                                    │
                                    │ SQL Queries
                                    ▼
┌──────────────────────────────────────┐
│   REPOSITORY LAYER                   │
│   src/repositories/                  │
│                                      │
│  QuizRepository::find_by_id()        │
│  SessionRepository::create_answer()  │
│  ReponseRepository::is_correct()     │
│                                      │
└──────────────┬───────────────────────┘
                │
                │ sqlx queries
                ▼
┌──────────────────────────────────────┐
│        PostgreSQL                    │
│                                      │
│  Tables:                             │
│   - quizzes (domain column)          │
│   - questions (media_url, target_id) │
│   - reponses                         │
│   - sessions_quiz                    │
│   - reponses_utilisateur             │
└──────────────────────────────────────┘


### FLOW DÉTAILLÉ : Soumettre une Réponse : 
Étape par étape avec le Plugin System
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 1. CLIENT envoie la réponse                                         │
   └─────────────────────────────────────────────────────────────────────┘
   POST /api/v1/sessions/abc-123/answers
   {
   "question_id": "def-456",
   "reponse_id": "ghi-789",  // Pour QCM
   "temps_reponse_sec": 8
   }
                               │
                               ▼
   ┌─────────────────────────────────────────────────────────────────────┐
   │ 2. ROUTER dispatche vers le handler                                 │
   └─────────────────────────────────────────────────────────────────────┘
   routes.rs: route("/sessions/:session_id/answers", post(handler))

   Handler reçoit:
    - State(app_state) ← CONTIENT pool + plugin_registry
    - Path(session_id)
   - Json(payload)
                                 │
                                 ▼
     ┌─────────────────────────────────────────────────────────────────────┐
     │ 3. HANDLER extrait les données et appelle le SERVICE                │
     └─────────────────────────────────────────────────────────────────────┘
                          │
                          ▼
      ┌─────────────────────────────────────────────────────────────────────┐
      │ 4. SERVICE - LOGIQUE MÉTIER                                         │
      └─────────────────────────────────────────────────────────────────────┘
     
                              │
                              ▼
      ┌─────────────────────────────────────────────────────────────────────┐
      │ 5. PLUGIN - Validation spécifique au domaine                        │
      └─────────────────────────────────────────────────────────────────────┘

                              │
                              ▼
      ┌─────────────────────────────────────────────────────────────────────┐
      │ 6. REPOSITORY - SQL Queries                                        │
      └─────────────────────────────────────────────────────────────────────┘
      reponse_repository.rs:

      SELECT is_correct
      FROM reponses
      WHERE id = $1 AND question_id = $2
                              │
                              ▼
      ┌─────────────────────────────────────────────────────────────────────┐
      │ 7. POSTGRESQL - Database                                           │
      └─────────────────────────────────────────────────────────────────────┘
      Exécute la requête SQL
      Retourne: is_correct = true


### A. AppState (Le Conteneur)
### B. PluginRegistry (L'annuaire)
### C. QuizPlugin Trait (Le contrat)
### D. Flow de Données
```


Request → Handler → Service → Plugin → Repository → Database
   ↓         ↓         ↓         ↓          ↓           ↓
  JSON    Extract   Business  Domain    SQL Query   PostgreSQL
          State     Logic     Logic


**Avant le Plugin System :**

Service → Repository → Database


**Maintenant :**

Service → PluginRegistry.get(domain) → Plugin.validate() → Repository → Database

```

[//]: # ()
[//]: # ()
[//]: # (### add geography seeds)

[//]: # ()
[//]: # (docker cp migrations/seeds/01_seed_geography_data.sql <NOM_CONTENEUR>:/tmp/01_seed_geography_data.sql)

[//]: # (docker exec -it <NOM_CONTENEUR> psql -U postgres -d geo_quiz_db -f /tmp/01_seed_geography_data.sql)

[//]: # (Get-Content migrations\seeds\01_seed_geography_data.sql | docker exec -i backend-postgres-quiz-1 psql -U quiz_user -d quiz_db)