📋 PLAN D'INTÉGRATION COMPLET - Services User, Monétisation & Hors-ligne
🎯 Objectif du Plan
Définir TOUTES les modifications nécessaires pour intégrer progressivement les 4 nouveaux services avec le quiz_core_service existant, en respectant la Clean Architecture et en maintenant la cohérence Frontend/Backend.

📊 CARTOGRAPHIE DES IMPACTS
Services à Créer (Nouveaux)

auth_service (Port 3001) - Authentification
subscription_service (Port 3002) - Abonnements & Crédits
offline_service (Port 3003) - Mode hors-ligne & Géolocalisation
ads_service (Port 3004) - Publicités & Freemium

Services à Modifier (Existants)

quiz_core_service (Port 8080) - Ajouter sécurité + access control
frontend Flutter - Intégrer chaque nouvelle fonctionnalité

Infrastructure à Ajouter

api_gateway (Port 8000) - Routage & Auth centralisée
PostgreSQL Cluster - 5 databases séparées
Shared Library - Types communs entre services


🗺️ PLAN GÉNÉRAL - 6 PHASES
PhaseDuréeObjectifLivrable1. Infrastructure1 semaineSetup multi-servicesDocker Compose fonctionnel2. Auth Service2 semainesAuthentification complèteService Auth + Frontend Auth3. Sécurisation Quiz1 semaineJWT + user_idQuiz Core sécurisé4. Subscription2 semainesAbonnements + IAPPaywall fonctionnel5. Offline & Ads2 semainesMode offline + PubsServices complets6. Intégration Finale2 semainesAPI Gateway + TestsProduction ready
Total : 10 semaines

📅 PHASE 1 : INFRASTRUCTURE MULTI-SERVICES
🎯 Objectif
Préparer l'environnement pour héberger 6 services + 5 databases sans casser l'existant.
📦 Backend - Modifications
1.1 Restructuration Arborescence
backend/
├── shared/                        ✅ Existant - À ENRICHIR
│   └── src/
│       ├── models/                🆕 Types communs
│       ├── dto/                   🆕 DTOs partagés
│       ├── clients/               🆕 Clients HTTP inter-services
│       └── error.rs               ✅ Existant
│
├── quiz_core_service/             ✅ Existant - À MODIFIER (Phase 3)
│
├── auth_service/                  🆕 À CRÉER (Phase 2)
├── subscription_service/          🆕 À CRÉER (Phase 4)
├── offline_service/               🆕 À CRÉER (Phase 5)
├── ads_service/                   🆕 À CRÉER (Phase 5)
└── api_gateway/                   🆕 À CRÉER (Phase 6)
Actions :

Créer dossiers vides pour nouveaux services
Enrichir shared/ avec structures communes
Documenter structure dans docs/architecture/

1.2 Docker Compose Multi-Databases
Fichier : docker/docker-compose.yml
À AJOUTER :

5 conteneurs PostgreSQL (ports 5432-5436)
Volumes persistants pour chaque DB
Networks dédiés (backend-network)
Health checks pour chaque service

Databases :
ServiceDatabasePortAuthauth_db5432Subscriptionsubs_db5433Offlineoffline_db5434Adsads_db5435Quiz Corequiz_db5436
1.3 Shared Library - Types Communs
Fichier : backend/shared/src/
À CRÉER :

models/user.rs : Type User partagé
models/subscription_status.rs : Enum UserStatus
dto/auth_dto.rs : Structures auth responses
clients/auth_client.rs : HTTP client vers Auth Service
clients/subscription_client.rs : HTTP client vers Subscription
config.rs : Configuration centralisée des URLs services

1.4 Scripts d'Initialisation
Dossier : docker/init-scripts/
À CRÉER :

init-auth-db.sql : Tables + seed applications
init-subs-db.sql : Tables subscription
init-offline-db.sql : Tables offline
init-ads-db.sql : Tables ads
init-quiz-db.sql : ✅ Existant - vérifier compatibilité

📱 Frontend - Modifications
1.5 Configuration Multi-Environnements
Fichiers :

lib/core/config/app_config.dart : 🔄 À MODIFIER
lib/core/config/environment.dart : 🆕 À CRÉER

À AJOUTER :

URLs pour chaque service (auth, subscription, quiz, etc.)
Configuration Dev / Staging / Prod
Feature flags pour activation progressive

1.6 Network Layer - Dio Setup
Fichier : lib/core/network/dio_client.dart
À MODIFIER :

Configuration base URLs multiples
Interceptors de base (logging, timeout)
Error handling centralisé

✅ Validation Phase 1

Docker Compose démarre tous les conteneurs
Toutes les databases sont créées et accessibles
Shared library compile sans erreur
Frontend compile avec nouvelles configs
Documentation architecture à jour


📅 PHASE 2 : SERVICE AUTH + FRONTEND AUTH
🎯 Objectif
Créer service Auth complet + Intégrer authentification dans Frontend.
📦 Backend - Auth Service
2.1 Structure Projet Auth Service
Dossier : backend/auth_service/
À CRÉER :
auth_service/
├── Cargo.toml                    🆕 Dépendances
├── Dockerfile                    🆕
├── src/
│   ├── main.rs                   🆕 Point d'entrée
│   ├── config.rs                 🆕 Config service
│   ├── models/                   🆕 7 fichiers
│   │   ├── user.rs
│   │   ├── oauth_connection.rs
│   │   ├── refresh_token.rs
│   │   ├── privacy_settings.rs
│   │   ├── game_center.rs
│   │   ├── audit_log.rs
│   │   └── mod.rs
│   ├── repositories/             🆕 5 fichiers
│   │   ├── user_repository.rs
│   │   ├── token_repository.rs
│   │   ├── oauth_repository.rs
│   │   ├── privacy_repository.rs
│   │   └── mod.rs
│   ├── services/                 🆕 4 fichiers
│   │   ├── auth_service.rs
│   │   ├── jwt_service.rs
│   │   ├── oauth_service.rs (Google/Apple)
│   │   └── mod.rs
│   ├── handlers/                 🆕 6 fichiers
│   │   ├── register.rs
│   │   ├── login.rs
│   │   ├── token.rs (refresh/logout)
│   │   ├── profile.rs
│   │   ├── privacy.rs
│   │   ├── game_center.rs
│   │   └── mod.rs
│   ├── middleware/               🆕 1 fichier
│   │   └── jwt_validator.rs
│   └── dto/                      🆕 4 fichiers
│       ├── register_dto.rs
│       ├── login_dto.rs
│       ├── token_dto.rs
│       └── mod.rs
└── migrations/                   🆕 5 fichiers SQL
├── 001_applications.sql
├── 002_users.sql
├── 003_oauth_connections.sql
├── 004_privacy_settings.sql
└── 005_game_center.sql
Total : ~30 fichiers à créer
2.2 Base de Données Auth
Fichiers : migrations/*.sql
Tables à créer (voir doc UC-AUTH) :

applications - Apps enregistrées
users - Utilisateurs
oauth_connections - Connexions Google/Apple
refresh_tokens - Tokens refresh
privacy_settings - Paramètres confidentialité
audit_logs - Logs connexions
game_center_connections - Liens Game Center
email_verification_tokens - Tokens vérification email
password_reset_tokens - Tokens reset password

Total : 9 tables + indexes
2.3 API Endpoints Auth
Routes à implémenter :

POST /auth/register - UC-AUTH-1.1
POST /auth/login - UC-AUTH-1.2
POST /auth/refresh
POST /auth/logout
GET /auth/me
PATCH /auth/me
DELETE /auth/me
GET /auth/privacy
PATCH /auth/privacy
POST /auth/privacy/export
POST /auth/game-center/link - UC-AUTH-1.3
POST /auth/password/forgot
POST /auth/password/reset

Total : 13 endpoints
2.4 Use Cases à Implémenter

✅ UC-AUTH-1.1 : Création compte (Google, Apple, Email, Guest)
✅ UC-AUTH-1.2 : Connexion
✅ UC-AUTH-1.3 : Sync Game Center
✅ UC-AUTH-1.4 : Gestion confidentialité

2.5 Tests Auth Service
À CRÉER :

Tests unitaires (repositories, services)
Tests d'intégration (endpoints)
Collection Postman/Insomnia
Documentation OpenAPI

📱 Frontend - Auth Integration
2.6 Auth SDK Flutter
À CRÉER :
lib/core/services/
├── auth/
│   ├── auth_service.dart         🆕 Service principal
│   ├── google_auth_provider.dart 🆕 Google Sign In
│   ├── apple_auth_provider.dart  🆕 Apple Sign In
│   └── auth_interceptor.dart     🆕 Interceptor JWT
Méthodes à implémenter :

registerWithGoogle(idToken)
registerWithApple(authCode)
registerWithEmail(email, password)
loginWithGoogle(idToken)
loginWithEmail(email, password)
logout()
getCurrentUser()
refreshToken()

2.7 Auth BLoC
À CRÉER :
lib/features/auth/
├── domain/
│   ├── entities/
│   │   └── user_entity.dart      🆕
│   └── repositories/
│       └── auth_repository.dart  🆕 Interface
├── data/
│   ├── models/
│   │   └── user_model.dart       🆕
│   ├── datasources/
│   │   └── auth_remote_datasource.dart 🆕
│   └── repositories/
│       └── auth_repository_impl.dart 🆕
└── presentation/
├── bloc/
│   ├── auth_bloc.dart        🆕
│   ├── auth_event.dart       🆕
│   └── auth_state.dart       🆕
├── pages/
│   ├── login_page.dart       🆕
│   ├── register_page.dart    🆕
│   └── profile_page.dart     🆕
└── widgets/
├── google_sign_in_button.dart 🆕
└── apple_sign_in_button.dart  🆕
Total : ~15 fichiers
2.8 Secure Storage
À CONFIGURER :

Package flutter_secure_storage
Stockage tokens (access_token, refresh_token)
Keychain iOS / Keystore Android

2.9 Navigation & Routing
À MODIFIER :

lib/core/routes/app_router.dart
Ajouter routes auth (/login, /register, /profile)
Guards pour routes protégées

✅ Validation Phase 2
Backend :

Auth Service démarre sur port 3001
Tous endpoints répondent correctement
JWT tokens générés et validés
Tests unitaires passent (>80% coverage)
Collection Postman validée

Frontend :

Login Google fonctionne
Login Apple fonctionne
Login Email fonctionne
Tokens stockés en sécurité
Interceptor JWT ajoute tokens automatiquement
Refresh automatique fonctionne
Logout efface tokens


📅 PHASE 3 : SÉCURISATION QUIZ CORE
🎯 Objectif
Intégrer Auth dans Quiz Core existant selon Clean Architecture.
📦 Backend - Quiz Core Service
3.1 Middleware JWT
À CRÉER :

src/middleware/auth.rs - Middleware validation JWT

Fonction optional_auth() - Auth optionnelle
Fonction require_auth() - Auth obligatoire
Fonction validate_with_auth_service() - Appel Auth Service
Struct AuthenticatedUser - Contexte user injecté



À MODIFIER :

src/main.rs - Appliquer middleware aux routes

3.2 Models - Cascade Clean Architecture
ÉTAPE 1 - Domain Models :

src/models/session.rs - Ajouter champs :

user_id: Option<Uuid>
is_authenticated: bool


src/models/quiz.rs - Ajouter champs :

access_level: AccessLevel (Free/Premium/Freemium)
credit_cost: Option<i32>



ÉTAPE 2 - Database Migration :

migrations/003_add_user_to_sessions.sql

ALTER TABLE quiz_sessions ADD COLUMN user_id
ALTER TABLE quiz_sessions ADD COLUMN is_authenticated
CREATE INDEX sur user_id


migrations/004_add_access_control_to_quizzes.sql

ALTER TABLE quizzes ADD COLUMN access_level
ALTER TABLE quizzes ADD COLUMN credit_cost



ÉTAPE 3 - DTOs :
À CRÉER :

src/dto/session_dto.rs

StartSessionRequest
SessionResponse
SubmitAnswerRequest
SubmitAnswerResponse


src/dto/quiz_dto.rs

QuizListResponse
QuizDetailResponse



ÉTAPE 4 - Repositories :
À MODIFIER :

src/repositories/session_repository.rs

Modifier create() - Accepter user_id: Option<Uuid>
Ajouter find_by_user() - Historique user
Modifier toutes queries SQL


src/repositories/quiz_repository.rs

Ajouter champs access_level dans queries



ÉTAPE 5 - Services :
À MODIFIER :

src/services/session_service.rs

Modifier start_session() - Accepter user_id
Ajouter get_user_history()
Retourner DTOs au lieu de models


src/services/quiz_service.rs

Modifier pour inclure access_level



ÉTAPE 6 - Handlers :
À MODIFIER :

src/handlers/session.rs

Extraire Extension<Option<AuthenticatedUser>>
Passer user_id aux services
Utiliser DTOs pour responses


src/handlers/quiz.rs

Adapter pour nouveaux champs



ÉTAPE 7 - Plugins (si applicable) :
À MODIFIER :

src/plugins/plugin_trait.rs

Ajouter paramètre user_context: Option<&UserContext>


Tous plugins existants (geography, etc.)

3.3 Client HTTP vers Auth Service
À CRÉER dans shared :

backend/shared/src/clients/auth_client.rs

Méthodes :

verify_token(token) → User
get_user(user_id) → User





3.4 Routes Protection
À ORGANISER dans main.rs :
Routes Publiques (pas de middleware) :
- GET /health
- GET /api/quiz (liste)
- GET /api/quiz/:id (détail)

Routes Semi-Protégées (optional_auth) :
- POST /api/quiz/:id/start

Routes Protégées (require_auth) :
- POST /api/session/:id/answer
- POST /api/session/:id/complete
- GET /api/user/sessions (historique)
  📱 Frontend - Quiz avec Auth
  3.5 Quiz Repository
  À MODIFIER :

lib/features/quiz/data/repositories/quiz_repository_impl.dart

Headers JWT automatiques (via interceptor)
Gérer erreurs 401 (redirect login)



3.6 Quiz BLoC
À MODIFIER :

lib/features/quiz/presentation/bloc/quiz_bloc.dart

Injecter AuthBloc en dépendance
Vérifier auth status avant start session
Gérer états authenticated / guest



Events à ajouter :

Aucun (utiliser events existants)

States à modifier :

QuizSessionStarted - Ajouter isAuthenticated: bool

3.7 UI Updates
À MODIFIER :

lib/features/quiz/presentation/pages/quiz_session_page.dart

Afficher banner "Mode invité" si non authentifié
Bouton "Créer compte" dans banner


lib/features/quiz/presentation/pages/quiz_list_page.dart

Badges "Premium" sur contenus premium



À CRÉER :

lib/features/quiz/presentation/widgets/guest_banner.dart
lib/features/quiz/presentation/widgets/premium_badge.dart

✅ Validation Phase 3
Backend :

Middleware JWT refuse requêtes sans token (routes protégées)
Middleware JWT accepte tokens valides
user_id extrait et stocké dans extensions
Sessions créées avec user_id
Historique user récupérable
Backward compatible (guest sessions fonctionnent)
Tests intégration Auth ↔ Quiz passent

Frontend :

Quiz démarrable sans auth (mode guest)
Quiz démarrable avec auth
Banner guest affiché correctement
Historique accessible pour users auth
Erreurs 401 gérées (redirect login)


📅 PHASE 4 : SERVICE SUBSCRIPTION
🎯 Objectif
Implémenter abonnements Apple/Google + Content access control.
📦 Backend - Subscription Service
4.1 Structure Projet
À CRÉER (~35 fichiers) :
subscription_service/
├── src/
│   ├── models/ (7 fichiers)
│   ├── repositories/ (6 fichiers)
│   ├── services/ (5 fichiers)
│   ├── handlers/ (8 fichiers)
│   ├── clients/ (3 fichiers - Apple/Google IAP)
│   └── dto/ (6 fichiers)
└── migrations/ (8 fichiers SQL)
4.2 Base de Données
Tables à créer :

subscriptions
subscription_plans
subscription_events
user_credits
credit_transactions
contents
unlocked_contents
access_logs
iap_receipts
webhook_events

4.3 Use Cases

✅ UC-SUB-2.1 : Souscription Apple IAP
✅ UC-SUB-2.2 : Vérification accès contenu
✅ UC-SUB-2.3 : Annulation abonnement
✅ UC-SUB-2.4 : Utilisation crédits

4.4 API Endpoints (15 endpoints)
Plans, Subscriptions, Credits, Content Access, Webhooks
📦 Backend - Quiz Core Integration
4.5 Client Subscription
À CRÉER dans shared :

backend/shared/src/clients/subscription_client.rs

check_content_access(user_id, content_id)
spend_credits(user_id, amount)
get_user_status(user_id)



4.6 Quiz Service - Access Control
À MODIFIER :

src/services/quiz_service.rs

Fonction start_quiz() :

Récupérer quiz avec access_level
Appeler Subscription Service
Bloquer si pas d'accès
Décrémenter crédits si freemium





📱 Frontend - Subscription
4.7 Subscription SDK
À CRÉER (~10 fichiers) :
lib/core/services/subscription/
├── subscription_service.dart
├── apple_iap_service.dart
├── google_iap_service.dart
└── subscription_interceptor.dart
4.8 Subscription BLoC
À CRÉER (~8 fichiers)
4.9 UI Paywall
À CRÉER :

Pages : Paywall, Plans, Manage Subscription
Widgets : Premium Badge, Unlock Dialog, Credits Display

✅ Validation Phase 4

Abonnements Apple IAP fonctionnent
Content access control effectif
Crédits système opérationnel
Quiz refuse accès premium sans abonnement
Paywall s'affiche correctement
Tests e2e passent


📅 PHASE 5 : SERVICES OFFLINE & ADS
🎯 Objectif
Mode hors-ligne + Publicités rewarded/interstitielles.
📦 Backend
5.1 Offline Service (~30 fichiers)

Structure complète
6 Use Cases
Database (8 tables)
API (12 endpoints)

5.2 Ads Service (~25 fichiers)

Structure complète
5 Use Cases
Database (6 tables)
API (10 endpoints)
Intégration AdMob

5.3 Quiz Core - Ads Trigger
À MODIFIER :

src/handlers/session.rs

Appeler Ads Service après complete_session()
Retourner show_ad: bool



📱 Frontend
5.4 Offline Service (~12 fichiers)

Download manager
SQLite local
Sync queue

5.5 Ads Service (~8 fichiers)

AdMob integration
Rewarded ads
Interstitial ads
Consent management

✅ Validation Phase 5

Téléchargement offline fonctionne
Jeu offline opérationnel
Sync queue effective
Pubs rewarded/interstitielles s'affichent
Consent GDPR/ATT géré


📅 PHASE 6 : INTÉGRATION FINALE
🎯 Objectif
API Gateway + Tests complets + Documentation.
📦 Backend
6.1 API Gateway
À CRÉER (~8 fichiers) :

Proxy vers services
Rate limiting
Logging centralisé

6.2 Tests End-to-End
À CRÉER (~15 fichiers de tests)
6.3 Documentation

OpenAPI specs (6 fichiers)
Architecture diagrams
Deployment guide

📱 Frontend
6.4 Tests E2E
À CRÉER :

Integration tests
Widget tests
Golden tests

6.5 CI/CD

GitHub Actions
Codemagic configuration

✅ Validation Phase 6

API Gateway route correctement
Tous tests passent
Documentation complète
Performance acceptable
Production ready

