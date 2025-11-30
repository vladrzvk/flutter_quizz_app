# 📘 DOCUMENTATION TECHNIQUE - QUIZ APP

## Table des matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Architecture Backend](#2-architecture-backend)
3. [Architecture Frontend](#3-architecture-frontend)
4. [Modèle de données](#4-modèle-de-données)
5. [Flux et séquences](#5-flux-et-séquences)
6. [Infrastructure Kubernetes](#6-infrastructure-kubernetes)
7. [Sécurité](#7-sécurité)
8. [CI/CD](#8-cicd)

---

## 1. Vue d'ensemble

### 1.1 Architecture globale

```
┌─────────────────────────────────────────────────────────────────┐
│                         QUIZ APPLICATION                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌─────────────────┐          ┌──────────────────────────────┐  │
│  │  Flutter App    │◄────────►│   Backend API (Rust/Axum)   │  │
│  │  (BLoC Pattern) │   HTTP   │   Plugin Architecture       │  │
│  └─────────────────┘          └────────────┬─────────────────┘  │
│                                             │                     │
│                                             ▼                     │
│                                  ┌──────────────────┐            │
│                                  │   PostgreSQL     │            │
│                                  │   (15-alpine)    │            │
│                                  └──────────────────┘            │
│                                                                   │
│  Infrastructure: Kubernetes (kind) + NGINX Ingress              │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Stack technologique

**Backend**
- Langage : Rust 1.90
- Framework : Axum 0.7
- Base de données : PostgreSQL 15 (SQLx)
- Architecture : Clean Architecture + Plugin System

**Frontend**
- Framework : Flutter 3.24.0
- État : flutter_bloc 8.1.3
- Architecture : Clean Architecture (Domain/Data/Presentation)
- Routing : go_router 13.0.0
- HTTP : dio 5.4.0

**Infrastructure**
- Orchestration : Kubernetes (kind pour local)
- Ingress : NGINX Ingress Controller
- CI/CD : GitHub Actions
- Containerisation : Docker

---

## 2. Architecture Backend

### 2.1 Structure du projet

```
backend/
├── quiz_core_service/          # Service principal
│   ├── src/
│   │   ├── config.rs          # Configuration (env vars)
│   │   ├── dto/               # Data Transfer Objects
│   │   ├── handlers/          # Axum route handlers
│   │   ├── models/            # Domain models
│   │   ├── plugins/           # ⭐ Système de plugins
│   │   │   ├── geography/     # Plugin Géographie
│   │   │   ├── plugin_trait.rs
│   │   │   └── registry.rs
│   │   ├── repositories/      # Data access layer
│   │   ├── routes.rs          # Route definitions
│   │   └── services/          # Business logic
│   └── migrations/            # SQL migrations
└── shared/                     # Bibliothèque partagée
    └── src/
        └── error.rs           # Gestion erreurs centralisée
```

### 2.2 Plugin Architecture ⭐

**Concept** : Chaque domaine de quiz (géographie, code route, etc.) est un plugin indépendant avec sa propre logique de validation.

```rust
// Trait que chaque plugin doit implémenter
#[async_trait]
pub trait QuizPlugin: Send + Sync {
    fn domain_name(&self) -> &str;
    
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

**Enregistrement des plugins** :

```rust
// main.rs
let mut plugin_registry = PluginRegistry::new();
plugin_registry.register(Arc::new(GeographyPlugin));
// Facile d'ajouter : plugin_registry.register(Arc::new(CodeRoutePlugin));
```

**Résolution dynamique** :

```rust
// Lors de la validation d'une réponse
let plugin = plugin_registry.get(&quiz.domain)
    .ok_or_else(|| AppError::NotFound(format!("No plugin for {}", quiz.domain)))?;

let validation = plugin.validate_answer(pool, question, answer).await?;
let points = plugin.calculate_score(base_points, &validation, time_spent, ...);
```

### 2.3 Flux de requête HTTP

```
Client Request
    ↓
NGINX Ingress (quiz-app.local)
    ↓
Service ClusterIP (quiz-backend:8080)
    ↓
Pod (quiz-backend)
    ↓
Axum Router
    ↓
Handler (quiz_handler.rs, session_handler.rs, etc.)
    ↓
Service (business logic)
    ↓
Repository (SQL queries via SQLx)
    ↓
PostgreSQL Database
    ↓
Response ← ← ← ← ← ← ←
```

### 2.4 Endpoints API principaux

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/v1/quizzes` | Liste des quiz |
| GET | `/api/v1/quizzes/:id` | Détails d'un quiz |
| GET | `/api/v1/quizzes/:quiz_id/questions` | Questions d'un quiz (avec réponses sans `is_correct`) |
| POST | `/api/v1/quizzes/:quiz_id/sessions` | Démarrer une session |
| POST | `/api/v1/sessions/:session_id/answers` | Soumettre une réponse |
| POST | `/api/v1/sessions/:session_id/finalize` | Finaliser session |
| GET | `/api/v1/sessions/:session_id` | Récupérer session |

---

## 3. Architecture Frontend

### 3.1 Clean Architecture (couches)

```
┌────────────────────────────────────────────────────────────┐
│                      PRESENTATION                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Pages      │  │    BLoCs     │  │   Widgets    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────┬──────────────────────────────────┘
                          │ Use Cases
┌─────────────────────────▼──────────────────────────────────┐
│                       DOMAIN                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Entities    │  │  Use Cases   │  │ Repositories │     │
│  │              │  │              │  │ (interface)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────┬──────────────────────────────────┘
                          │ Implementation
┌─────────────────────────▼──────────────────────────────────┐
│                        DATA                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Models     │  │ Repositories │  │ DataSources  │     │
│  │  (Freezed)   │  │    (Impl)    │  │   (Dio)      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└────────────────────────────────────────────────────────────┘
```

### 3.2 Injection de dépendances (GetIt)

```dart
// injection_container.dart
final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Dio Client
  sl.registerLazySingleton<Dio>(() => Dio(...));
  
  // DataSources
  sl.registerLazySingleton<QuizRemoteDataSource>(
    () => QuizRemoteDataSourceImpl(dio: sl())
  );
  
  // Repositories
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(remoteDataSource: sl())
  );
  
  // Use Cases
  sl.registerLazySingleton(() => GetQuizList(sl()));
  sl.registerLazySingleton(() => StartQuizSession(sl()));
  sl.registerLazySingleton(() => SubmitAnswer(sl()));
  
  // BLoCs (Factory - nouvelle instance)
  sl.registerFactory(() => QuizListBloc(...));
  sl.registerFactory(() => QuizSessionBloc(...));
}
```

### 3.3 Gestion d'état (BLoC)

**Exemple : QuizSessionBloc**

```dart
// États
sealed class QuizSessionState
class QuizSessionInitial extends QuizSessionState
class QuizSessionLoading extends QuizSessionState
class QuizSessionInProgress extends QuizSessionState
class QuizAnswerSubmitted extends QuizSessionState
class QuizSessionCompleted extends QuizSessionState
class QuizSessionError extends QuizSessionState

// Événements
sealed class QuizSessionEvent
class StartQuizSessionEvent extends QuizSessionEvent
class SubmitAnswerEvent extends QuizSessionEvent
class NextQuestionEvent extends QuizSessionEvent
class FinalizeQuizSessionEvent extends QuizSessionEvent

// Transitions
QuizSessionInitial → StartQuizSessionEvent → QuizSessionInProgress
QuizSessionInProgress → SubmitAnswerEvent → QuizAnswerSubmitted
QuizAnswerSubmitted → NextQuestionEvent → QuizSessionInProgress (ou Completed)
```

---

## 4. Modèle de données

### 4.1 Schéma de base de données

```sql
-- Domaines disponibles (geography, code_route, etc.)
domains
  ├── id (UUID, PK)
  ├── name (VARCHAR, UNIQUE) -- 'geography'
  ├── display_name (VARCHAR) -- 'Géographie'
  └── config (JSONB)

-- Quiz
quizzes
  ├── id (UUID, PK)
  ├── domain (VARCHAR, FK → domains.name) ⭐
  ├── titre (VARCHAR)
  ├── scope (VARCHAR) -- 'france', 'europe', 'monde'
  ├── mode (VARCHAR) -- 'decouverte', 'entrainement', 'examen'
  ├── niveau_difficulte (VARCHAR) -- 'facile', 'moyen', 'difficile'
  └── nb_questions (INTEGER)

-- Questions
questions
  ├── id (UUID, PK)
  ├── quiz_id (UUID, FK → quizzes)
  ├── ordre (INTEGER)
  ├── type_question (VARCHAR) -- 'qcm', 'vrai_faux', 'saisie_texte'
  ├── question_data (JSONB) -- {"text": "..."}
  ├── category (VARCHAR) ⭐ -- 'fleuves', 'reliefs', 'pays_regions'
  ├── subcategory (VARCHAR) ⭐ -- 'hydrographie', 'montagnes'
  ├── points (INTEGER)
  ├── temps_limite_sec (INTEGER, nullable)
  ├── hint (TEXT, nullable)
  └── explanation (TEXT, nullable)

-- Réponses possibles (pour QCM/Vrai-Faux)
reponses
  ├── id (UUID, PK)
  ├── question_id (UUID, FK → questions)
  ├── valeur (TEXT, nullable) -- "La Loire", "Vrai", etc.
  ├── is_correct (BOOLEAN) ⚠️ Jamais exposé au client
  └── ordre (INTEGER)

-- Sessions de quiz (partie jouée)
sessions_quiz
  ├── id (UUID, PK)
  ├── user_id (UUID)
  ├── quiz_id (UUID, FK → quizzes)
  ├── score (INTEGER, default 0)
  ├── score_max (INTEGER)
  ├── pourcentage (DOUBLE, auto-calculé)
  ├── status (VARCHAR) -- 'en_cours', 'termine', 'abandonne'
  └── date_debut (TIMESTAMPTZ)

-- Réponses utilisateur
reponses_utilisateur
  ├── id (UUID, PK)
  ├── session_id (UUID, FK → sessions_quiz)
  ├── question_id (UUID, FK → questions)
  ├── reponse_id (UUID, FK → reponses, nullable) -- Pour QCM
  ├── valeur_saisie (TEXT, nullable) -- Pour saisie texte
  ├── is_correct (BOOLEAN) ✅ Calculé côté backend
  ├── points_obtenus (INTEGER)
  └── temps_reponse_sec (INTEGER)
```

### 4.2 Relations

```
domains 1──────* quizzes
quizzes 1──────* questions
questions 1────* reponses
quizzes 1──────* sessions_quiz
sessions_quiz 1──* reponses_utilisateur
questions 1────* reponses_utilisateur
```

### 4.3 Modèles Rust (Backend)

```rust
// models/quiz.rs
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Quiz {
    pub id: Uuid,
    pub domain: String,          // ⭐ 'geography', 'code_route'
    pub titre: String,
    pub scope: String,           // 'france', 'europe'
    pub mode: String,            // 'decouverte', 'entrainement'
    pub niveau_difficulte: String,
    pub nb_questions: i32,
    // ...
}

// models/question.rs
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Question {
    pub id: Uuid,
    pub quiz_id: Uuid,
    pub type_question: String,   // 'qcm', 'vrai_faux', 'saisie_texte'
    pub question_data: serde_json::Value,
    pub category: Option<String>,
    pub subcategory: Option<String>,
    pub points: i32,
    pub temps_limite_sec: Option<i32>,
    // ...
}
```

### 4.4 Modèles Flutter (Frontend)

```dart
// Freezed models avec JSON serialization
@freezed
class QuizModel with _$QuizModel {
  const factory QuizModel({
    required String id,
    @JsonKey(name: 'domain') required String domain,
    required String titre,
    @JsonKey(name: 'scope') required String scope,
    @JsonKey(name: 'mode') required String mode,
    @JsonKey(name: 'niveau_difficulte') required String niveauDifficulte,
    @JsonKey(name: 'nb_questions') required int nbQuestions,
    // ...
  }) = _QuizModel;
  
  factory QuizModel.fromJson(Map<String, dynamic> json) =>
      _$QuizModelFromJson(json);
}

// Mapping Model → Entity (Domain)
extension QuizModelMapper on QuizModel {
  QuizEntity toEntity() {
    return QuizEntity(
      id: id,
      domain: domain,
      titre: titre,
      // ...
    );
  }
}
```

---

## 5. Flux et séquences

### 5.1 Démarrage d'une session de quiz

```
┌──────┐         ┌─────────┐      ┌─────────┐      ┌──────────┐      ┌────────┐
│Client│         │ Backend │      │ Service │      │Repository│      │   DB   │
└──┬───┘         └────┬────┘      └────┬────┘      └────┬─────┘      └───┬────┘
   │                  │                 │                │                │
   │ POST /quizzes/   │                 │                │                │
   │ :id/sessions     │                 │                │                │
   ├─────────────────►│                 │                │                │
   │ {user_id}        │                 │                │                │
   │                  │                 │                │                │
   │           start_session_handler()  │                │                │
   │                  ├────────────────►│                │                │
   │                  │                 │                │                │
   │                  │          get_quiz_questions()   │                │
   │                  │                 ├───────────────►│                │
   │                  │                 │                │   SELECT       │
   │                  │                 │                ├───────────────►│
   │                  │                 │                │                │
   │                  │                 │      Questions◄────────────────┤
   │                  │                 ◄────────────────┤                │
   │                  │                 │                │                │
   │                  │          create_session()       │                │
   │                  │                 ├───────────────►│                │
   │                  │                 │                │   INSERT       │
   │                  │                 │                ├───────────────►│
   │                  │                 │                │                │
   │                  │          Session◄────────────────┤  session_id   │
   │                  │                 ◄────────────────┤                │
   │                  │                 │                │                │
   │         200 OK   ◄─────────────────┤                │                │
   ◄──────────────────┤                 │                │                │
   │ {session,        │                 │                │                │
   │  questions}      │                 │                │                │
   │                  │                 │                │                │
```

### 5.2 Soumission d'une réponse (avec plugin)

```
┌──────┐    ┌─────────┐    ┌─────────┐    ┌────────┐    ┌──────┐    ┌────┐
│Client│    │ Backend │    │ Service │    │ Plugin │    │ Repo │    │ DB │
└──┬───┘    └────┬────┘    └────┬────┘    └───┬────┘    └──┬───┘    └─┬──┘
   │             │               │             │            │           │
   │ POST        │               │             │            │           │
   │ /sessions/  │               │             │            │           │
   │ :id/answers │               │             │            │           │
   ├────────────►│               │             │            │           │
   │ {question_id│               │             │            │           │
   │  reponse_id │               │             │            │           │
   │  time}      │               │             │            │           │
   │             │               │             │            │           │
   │      submit_answer()        │             │            │           │
   │             ├──────────────►│             │            │           │
   │             │               │             │            │           │
   │             │          get_quiz()        │            │           │
   │             │               ├────────────┼───────────►│           │
   │             │               │             │            │  SELECT   │
   │             │               │             │            ├──────────►│
   │             │               │             │            │           │
   │             │               │      Quiz  ◄────────────┤           │
   │             │               ◄────────────┼────────────┤           │
   │             │               │             │            │           │
   │             │          get_plugin(domain)│            │           │
   │             │               ├────────────►            │           │
   │             │               │     PluginGeography     │           │
   │             │               ◄────────────┤            │           │
   │             │               │             │            │           │
   │             │          validate_answer() │            │           │
   │             │               ├────────────►            │           │
   │             │               │             │            │           │
   │             │               │      ValidationResult   │           │
   │             │               ◄────────────┤            │           │
   │             │               │  {is_correct, feedback} │           │
   │             │               │             │            │           │
   │             │          calculate_score() │            │           │
   │             │               ├────────────►            │           │
   │             │               │             │            │           │
   │             │               │      points ◄───────────┤           │
   │             │               ◄────────────┤            │           │
   │             │               │             │            │           │
   │             │          create_user_answer()          │           │
   │             │               ├────────────┼───────────►│           │
   │             │               │             │            │  INSERT   │
   │             │               │             │            ├──────────►│
   │             │               │             │            │           │
   │             │          update_score()    │            │           │
   │             │               ├────────────┼───────────►│           │
   │             │               │             │            │  UPDATE   │
   │             │               │             │            ├──────────►│
   │             │               │             │            │           │
   │      200 OK ◄───────────────┤             │            │           │
   ◄─────────────┤               │             │            │           │
   │ {answer,    │               │             │            │           │
   │  is_correct,│               │             │            │           │
   │  points}    │               │             │            │           │
   │             │               │             │            │           │
```

**Points clés** :
1. Le backend récupère le domaine du quiz (`geography`)
2. Il sélectionne le plugin correspondant (`GeographyPlugin`)
3. Le plugin valide la réponse selon sa logique propre
4. Le plugin calcule le score (avec bonus vitesse, streak, etc.)
5. La réponse utilisateur est enregistrée avec `is_correct` et `points_obtenus`

### 5.3 Validation par type de question (GeographyPlugin)

```
┌──────────────────────────────────────────────────────────┐
│              GeographyPlugin::validate_answer()           │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  switch (question.type_question) {                        │
│                                                            │
│    case "qcm":                                            │
│      ├─► SELECT is_correct FROM reponses                 │
│      │   WHERE id = :reponse_id                          │
│      └─► return ValidationResult { is_correct, ... }     │
│                                                            │
│    case "vrai_faux":                                      │
│      ├─► SELECT is_correct FROM reponses                 │
│      │   WHERE id = :reponse_id                          │
│      └─► return ValidationResult { is_correct, ... }     │
│                                                            │
│    case "saisie_texte":                                   │
│      ├─► normalize(valeur_saisie) // lowercase + trim    │
│      ├─► SELECT LOWER(valeur) FROM reponses              │
│      │   WHERE question_id = :id AND is_correct = true   │
│      ├─► compare normalized values                       │
│      └─► return ValidationResult { is_correct, ... }     │
│                                                            │
│    case "carte_cliquable": (V1 - pas encore)             │
│      └─► return Error("Not implemented")                 │
│  }                                                         │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 6. Infrastructure Kubernetes

### 6.1 Architecture Kubernetes (kind local)

```
┌────────────────────────────────────────────────────────────────┐
│                         KIND CLUSTER                            │
│                                                                  │
│  ┌─────────────────────────────────────────────────────┐       │
│  │              Namespace: ingress-nginx               │       │
│  │  ┌───────────────────────────────────────────┐     │       │
│  │  │  NGINX Ingress Controller (NodePort)     │     │       │
│  │  └─────────────────┬─────────────────────────┘     │       │
│  └────────────────────┼───────────────────────────────┘       │
│                       │                                         │
│                       ▼ (routes quiz-app.local)                │
│  ┌─────────────────────────────────────────────────────┐       │
│  │              Namespace: quiz-app                    │       │
│  │                                                      │       │
│  │  ┌─────────────────────────────────────────┐       │       │
│  │  │  Ingress Resource                        │       │       │
│  │  │  Host: quiz-app.local                    │       │       │
│  │  └─────────────┬────────────────────────────┘       │       │
│  │                │                                     │       │
│  │                ▼                                     │       │
│  │  ┌─────────────────────────────────────────┐       │       │
│  │  │  Service: quiz-backend (ClusterIP)      │       │       │
│  │  └─────────────┬────────────────────────────┘       │       │
│  │                │                                     │       │
│  │                ▼                                     │       │
│  │  ┌─────────────────────────────────────────┐       │       │
│  │  │  Deployment: quiz-backend (2 replicas)  │       │       │
│  │  │  Image: quiz-backend:local               │       │       │
│  │  │  Resources: 128Mi-512Mi / 100m-400m      │       │       │
│  │  └─────────────┬────────────────────────────┘       │       │
│  │                │                                     │       │
│  │                ▼                                     │       │
│  │  ┌─────────────────────────────────────────┐       │       │
│  │  │  Service: postgres (Headless)           │       │       │
│  │  └─────────────┬────────────────────────────┘       │       │
│  │                │                                     │       │
│  │                ▼                                     │       │
│  │  ┌─────────────────────────────────────────┐       │       │
│  │  │  StatefulSet: postgres (1 replica)      │       │       │
│  │  │  Image: postgres:15-alpine               │       │       │
│  │  │  PVC: 10Gi                               │       │       │
│  │  └──────────────────────────────────────────┘       │       │
│  │                                                      │       │
│  │  ConfigMap: quiz-config (env vars)                 │       │
│  │  Secret: quiz-secrets (DATABASE_URL, JWT_SECRET)   │       │
│  │  NetworkPolicies: isolation réseau                 │       │
│  │  ResourceQuota + LimitRange: limits CPU/RAM        │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                  │
└────────────────────────────────────────────────────────────────┘
```

### 6.2 Sécurité Kubernetes (Pod Security Standards)

**Namespace** : `pod-security.kubernetes.io/enforce: restricted`

**Backend Deployment** :
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  fsGroup: 65532
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
```

**PostgreSQL StatefulSet** :
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 999  # postgres user
  fsGroup: 999
  readOnlyRootFilesystem: false  # PostgreSQL needs to write
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
```

### 6.3 Network Policies

```yaml
# Default: DENY ALL
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]

# PostgreSQL: accepte SEULEMENT backend
kind: NetworkPolicy
metadata:
  name: postgres-allow-backend
spec:
  podSelector:
    matchLabels: {app: postgres}
  ingress:
    - from:
      - podSelector:
          matchLabels: {app: quiz-backend}
      ports:
        - protocol: TCP
          port: 5432

# Backend: accepte Ingress + communique PostgreSQL
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels: {app: quiz-backend}
  ingress:
    - from:
      - namespaceSelector:
          matchLabels: {name: ingress-nginx}
      ports:
        - protocol: TCP
          port: 8080
  egress:
    - to:
      - podSelector:
          matchLabels: {app: postgres}
      ports:
        - protocol: TCP
          port: 5432
```

---

## 7. Sécurité

### 7.1 Backend

**Principe du moindre privilège**
- ServiceAccount dédiés sans token auto-monté
- Secrets pour credentials (jamais en clair dans code)
- Validation des entrées utilisateur
- `is_correct` jamais exposé dans l'API GET questions

**Plugin System**
- Isolation logique : chaque domaine valide ses réponses indépendamment
- Impossible de tricher en manipulant les réponses (validation côté serveur)

### 7.2 Frontend

**Sécurité des données**
- Aucune donnée sensible stockée localement
- Tous les secrets côté backend uniquement
- HTTPS en production (TLS via cert-manager)

**Validation**
- Les réponses sont toujours validées côté backend
- Le frontend affiche uniquement le résultat renvoyé par l'API

### 7.3 Infrastructure

**Kubernetes**
- Pod Security Standards: `restricted`
- RBAC minimal
- Network Policies: zero-trust par défaut
- Resource Quotas & LimitRanges
- ReadOnlyRootFilesystem quand possible

**NGINX Ingress**
- Rate limiting (100 req/s)
- Security headers (X-Frame-Options, CSP, etc.)
- CORS configuré (à restreindre en production)

---

## 8. CI/CD

### 8.1 GitHub Actions Workflows

**Actuellement archivés** (`/.github/archived/workflows/`)
- `backend-ci.yml` : Tests + Build Docker
- `backend-cd.yml` : Déploiement K8s
- `frontend-ci.yml` : Tests Flutter
- `coverage-manual.yml` : Code coverage

**Actifs** (`/.github/workflows/`)
- `format.yml` : Vérification formatage (Rust + Dart)
- `tests-manuel.yml` : Tests backend manuels
- `coverage-manual.yml` : Coverage manuel

### 8.2 Workflow type (backend-ci.yml - archivé mais référence)

```yaml
jobs:
  lint:
    - cargo fmt --check
    - cargo clippy -- -D warnings
  
  test:
    services:
      postgres:
        image: postgres:15
    steps:
      - sqlx migrate run
      - cargo test --verbose
  
  build:
    needs: [lint, test]
    steps:
      - docker build -t ghcr.io/.../quiz-backend:$SHA
      - docker push
      - trivy scan (vulnérabilités)
```

### 8.3 Déploiement (backend-cd.yml - archivé)

```yaml
deploy:
  environment: ${{ inputs.environment || 'staging' }}
  steps:
    - kubectl set image deployment/quiz-backend ...
    - kubectl rollout status
    - smoke tests (health + API)
    - rollback si échec
    - notification Slack
```

---

## 9. Diagrammes complémentaires

### 9.1 Diagramme de classes (domaine Quiz)

```
┌──────────────────┐
│      Quiz        │
├──────────────────┤
│ id: UUID         │
│ domain: String   │◄──────┐
│ titre: String    │       │
│ scope: String    │       │ 1
│ mode: String     │       │
└────────┬─────────┘       │
         │ 1                │
         │                  │
         │ *                │
         ▼                  │
┌──────────────────┐       │
│    Question      │       │
├──────────────────┤       │
│ id: UUID         │       │
│ quiz_id: UUID    │───────┘
│ type: String     │
│ category: String │
│ points: i32      │
└────────┬─────────┘
         │ 1
         │
         │ *
         ▼
┌──────────────────┐
│     Reponse      │
├──────────────────┤
│ id: UUID         │
│ valeur: String   │
│ is_correct: bool │ ⚠️ Secret
└──────────────────┘
```

### 9.2 État d'une session

```
     START
       │
       ▼
   ┌─────────┐
   │ INITIAL │
   └────┬────┘
        │ StartQuizSessionEvent
        ▼
   ┌─────────────┐
   │ IN_PROGRESS │◄────────┐
   └─────┬───────┘         │
         │                 │
         │ SubmitAnswer    │
         ▼                 │
   ┌──────────────┐        │
   │   ANSWERED   │        │
   └─────┬────────┘        │
         │                 │
         │ NextQuestion    │
         ├─────────────────┘
         │
         │ (last question)
         ▼
   ┌───────────┐
   │ COMPLETED │
   └───────────┘
        │
        ▼
      END
```

---

## Conclusion

Cette architecture offre :

✅ **Extensibilité** : Ajout facile de nouveaux domaines via plugins  
✅ **Maintenabilité** : Clean Architecture + séparation des responsabilités  
✅ **Sécurité** : Pod Security, Network Policies, validation serveur  
✅ **Performance** : Kubernetes HPA-ready, StatefulSet pour PostgreSQL  
✅ **Testabilité** : Découplage via interfaces, injection de dépendances

**Prochaines évolutions** :
- Questions type `carte_cliquable` (V1)
- Plugin `CodeRoutePlugin` pour code de la route
- TLS/HTTPS via cert-manager
- Monitoring (Prometheus + Grafana)
- Observabilité (OpenTelemetry)