📊 Architecture Quiz Core Service
Structure Microservices
quiz_core_service/          (Port 8080)
├── src/
│   ├── models/
│   │   ├── quiz.rs           # Modèle Quiz avec field: domain
│   │   ├── question.rs       # Question générique
│   │   ├── answer.rs         # Réponse générique
│   │   └── session.rs        # Session de jeu
│   ├── repositories/         # Data access layer
│   ├── services/
│   │   ├── quiz_service.rs
│   │   ├── scoring_service.rs
│   │   └── validation_service.rs
│   ├── handlers/             # API endpoints
│   └── plugins/              # 🔌 Plugin System
│       ├── mod.rs
│       ├── plugin_trait.rs
│       └── registry.rs
Responsabilités

CRUD Quiz/Questions : Création, lecture, mise à jour, suppression
Sessions de jeu : Gestion des parties en cours
Scoring : Calcul des scores, statistiques
Plugin System : Extensibilité par domaine (Geography, Code Route, etc.)
Database : PostgreSQL (quiz_db)

Services Complémentaires (Prévus)

geography_service (8081) : Régions, pays, traductions
map_service (8082) : PostGIS, géométries, tuiles vectorielles

Frontend Flutter

Clean Architecture + BLoC
Modules : quiz, geography, maps
Hot reload configuré

🔗 Intégration avec les Nouveaux Services
Maintenant qu'on a défini les services Auth, Subscription, Offline et Ads, voici comment ils s'intègrent avec le quiz_core_service :
Architecture Complète
┌─────────────────────────────────────────────────────────────┐
│                    FRONTEND FLUTTER                         │
│   (Quiz UI, Geography Plugin, Auth, Payment, Ads)          │
└────────────────────┬────────────────────────────────────────┘
│
REST API (JSON)
│
┌────────────────────┴────────────────────────────────────────┐
│                     API GATEWAY                             │
│              (Kong/Traefik - Port 8000)                     │
│   - Routing                                                 │
│   - Authentication (JWT validation)                         │
│   - Rate limiting                                           │
└───┬─────┬─────┬─────┬─────┬─────────────────────────────────┘
│     │     │     │     │
▼     ▼     ▼     ▼     ▼
┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ ┌──────────────┐
│Auth │ │Subs │ │Offl.│ │Ads  │ │ Quiz Core    │
│3001 │ │3002 │ │3003 │ │3004 │ │    8080      │
└─────┘ └─────┘ └─────┘ └─────┘ └──────────────┘
│       │       │       │            │
│       │       │       │            │
▼       ▼       ▼       ▼            ▼
┌────────────────────────────────────────────┐
│            PostgreSQL Cluster              │
│  auth_db | subs_db | offline_db | ads_db  │
│                quiz_db | geography_db      │
└────────────────────────────────────────────┘
Communication Inter-Services
Quiz Core Service doit maintenant communiquer avec :

Auth Service (3001)

Valider JWT tokens
Vérifier user_id
Récupérer user status (free/premium)


Subscription Service (3002)

Vérifier accès contenu premium
Décrémenter crédits si contenu freemium
Logger access attempts


Offline Service (3003)

Fournir questions pour download
Recevoir réponses en sync queue
Valider sessions offline


Ads Service (3004)

Notifier fin de quiz (trigger interstitiel)
Vérifier si user peut voir contenu sans pub



Exemple : Flow Complet "Jouer un Quiz"
1. User lance quiz depuis Flutter
   ↓
2. App → Auth Service (3001)
   GET /auth/me (valide token)
   ← { user_id, status: 'premium' }
   ↓
3. App → Quiz Core (8080)
   POST /api/quiz/start
   Headers: { Authorization: Bearer token }
   ↓
4. Quiz Core → Auth Service
   Valide JWT, extrait user_id
   ↓
5. Quiz Core → Subscription Service (3002)
   GET /content/:quiz_id/check-access
   ← { has_access: true }
   ↓
6. Quiz Core crée session
   ← { session_id, questions[] }
   ↓
7. User répond aux questions
   ↓
8. App → Quiz Core
   POST /api/session/:id/submit
   ↓
9. Quiz Core calcule score
   ↓
10. Si user FREE → Quiz Core → Ads Service (3004)
    POST /ads/trigger-interstitial
    Placement: 'post_quiz'
    ↓
11. Quiz Core retourne résultats
    ← { score, correct_answers, show_ad: true }
    🔧 Modifications Nécessaires Quiz Core Service
    Pour intégrer avec les nouveaux services, quiz_core_service doit :
1. Ajouter Middleware Authentication
   rust// src/middleware/auth.rs
   pub async fn validate_jwt(
   headers: HeaderMap,
   ) -> Result<UserId, AuthError> {
   let token = extract_bearer_token(headers)?;

   // Call Auth Service pour validation
   let client = reqwest::Client::new();
   let resp = client
   .get("http://auth-service:3001/auth/verify")
   .bearer_auth(token)
   .send()
   .await?;

   let user = resp.json::<User>().await?;
   Ok(user.id)
   }
2. Vérifier Accès Contenu
   rust// src/services/quiz_service.rs
   pub async fn start_quiz(
   user_id: UserId,
   quiz_id: QuizId,
   ) -> Result<Session, QuizError> {
   // Check access avec Subscription Service
   let has_access = subscription_client
   .check_access(user_id, quiz_id)
   .await?;

   if !has_access {
   return Err(QuizError::AccessDenied {
   unlock_options: subscription_client
   .get_unlock_options(user_id, quiz_id)
   .await?
   });
   }

   // Create session...
   }
3. Intégrer Offline Sync
   rust// src/handlers/offline.rs
   pub async fn download_quiz_offline(
   user_id: UserId,
   quiz_id: QuizId,
   ) -> Result<OfflineQuiz, Error> {
   // Verify limits avec Offline Service
   let limits = offline_client
   .get_user_limits(user_id)
   .await?;

   if limits.categories_downloaded >= limits.max_categories {
   return Err(Error::LimitReached);
   }

   // Return quiz data for offline storage
   let quiz = quiz_repository.get_with_questions(quiz_id).await?;
   Ok(quiz.into_offline_format())
   }
4. Trigger Ads
   rust// src/handlers/session.rs
   pub async fn complete_session(
   user_id: UserId,
   session_id: SessionId,
   ) -> Result<SessionResult, Error> {
   let result = calculate_results(session_id).await?;

   // Check si user FREE
   let user = auth_client.get_user(user_id).await?;

   let show_ad = if user.status == UserStatus::Free {
   // Notify Ads Service
   ads_client.should_show_interstitial(
   user_id,
   "post_quiz"
   ).await?
   } else {
   false
   };

   Ok(SessionResult {
   score: result.score,
   show_ad,
   ...
   })
   }
   📝 Modèle de Données Étendu
   Quiz avec Access Control
   rust// src/models/quiz.rs
   #[derive(Serialize, Deserialize)]
   pub struct Quiz {
   pub id: Uuid,
   pub title: String,
   pub domain: Domain, // geography, code_route, etc.
   pub access_level: AccessLevel, // ← NOUVEAU
   pub credit_cost: Option<i32>, // ← NOUVEAU
   pub questions: Vec<Question>,
   }

#[derive(Serialize, Deserialize)]
pub enum AccessLevel {
Free,
Premium,
Freemium,
}