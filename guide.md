# 📗 GUIDE D'UTILISATION - QUIZ APP

## Table des matières

1. [Installation locale](#1-installation-locale)
2. [Utilisation de l'API](#2-utilisation-de-lapi)
3. [Utilisation de l'application Flutter](#3-utilisation-de-lapplication-flutter)
4. [Workflows de développement](#4-workflows-de-développement)
5. [Déploiement](#5-déploiement)
6. [Résolution de problèmes](#6-résolution-de-problèmes)

---

## 1. Installation locale

### 1.1 Prérequis

**Outils requis** :
- Docker Desktop (Windows/Mac) ou Docker Engine (Linux)
- kubectl (client Kubernetes)
- kind (Kubernetes in Docker)
- Rust 1.90+ (pour développement backend)
- Flutter 3.24+ (pour développement frontend)

**Vérification** :
```bash
# Docker
docker --version
docker ps

# Kubernetes
kubectl version --client

# kind
kind version

# Rust (optionnel pour dev)
rustc --version
cargo --version

# Flutter (optionnel pour dev)
flutter --version
```

### 1.2 Option A : Docker Compose (développement simple)

**Lancement rapide** :
```bash
# 1. Cloner le projet
git clone <repo-url>
cd quiz-app

# 2. Lancer PostgreSQL + Redis
docker-compose up -d

# 3. Vérifier
docker ps
# ✅ Devrait afficher : quiz-postgres, quiz-redis

# 4. Créer le schéma
cd backend/quiz_core_service
cargo install sqlx-cli --no-default-features --features postgres
sqlx migrate run

# 5. Lancer le backend (en local, pas Docker)
cargo run
# ✅ Backend sur http://localhost:8080
```

**Test santé** :
```bash
curl http://localhost:8080/health
# {"status":"healthy","service":"quiz_core_service","version":"0.1.0"}
```

### 1.3 Option B : Kubernetes kind (proche production)

**Création du cluster** :

```bash
# 1. Naviguer vers les manifests Kubernetes
cd k8s/kind

# 2. Créer le cluster kind (via Docker Desktop UI ou CLI)
# Via CLI:
kind create cluster --config kind-config.yaml --name quiz-cluster

# Via Docker Desktop:
# - Ouvrir Docker Desktop
# - Kubernetes tab → Create → kind
# - Nodes: 3 (1 control-plane + 2 workers)
# - Attendre 2-3 min

# 3. Vérifier le cluster
kubectl get nodes
# NAME                          STATUS   ROLE           AGE
# quiz-cluster-control-plane    Ready    control-plane  2m
# quiz-cluster-worker           Ready    <none>         2m
# quiz-cluster-worker2          Ready    <none>         2m
```

**Installation NGINX Ingress** :

```bash
# Installer le controller
kubectl apply -f manifests/000-my-ingress.yaml

# Attendre qu'il soit prêt
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Vérifier
kubectl get pods -n ingress-nginx
# NAME                                       READY   STATUS    RESTARTS   AGE
# ingress-nginx-controller-xxxxx             1/1     Running   0          1m
```

**Build de l'image backend** :

```bash
# Depuis la racine du projet
cd backend
docker build -t quiz-backend:local -f ../docker/backend.Dockerfile .

# Vérifier
docker images | grep quiz-backend
# quiz-backend   local   xxxxx   2 minutes ago   XXX MB
```

**Déploiement de l'application** :

```bash
# Retour aux manifests K8s
cd ../k8s/kind

# Déployer tout (namespace, secrets, postgres, backend, ingress)
kubectl apply -f manifests/

# Vérifier le déploiement
kubectl get all -n quiz-app

# Exemple de sortie :
# NAME                               READY   STATUS    RESTARTS   AGE
# pod/quiz-backend-xxxxxxxxx-xxxxx   1/1     Running   0          1m
# pod/quiz-backend-xxxxxxxxx-xxxxx   1/1     Running   0          1m
# pod/postgres-0                     1/1     Running   0          2m
#
# NAME                   TYPE        CLUSTER-IP      PORT(S)
# service/postgres       ClusterIP   None            5432/TCP
# service/quiz-backend   ClusterIP   10.96.xxx.xxx   8080/TCP
#
# NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/quiz-backend   2/2     2            2           1m
#
# NAME                             DESIRED   CURRENT   READY   AGE
# statefulset.apps/postgres        1         1         1       2m
```

**Configuration `/etc/hosts`** :

Windows : `C:\Windows\System32\drivers\etc\hosts`
Linux/Mac : `/etc/hosts`

```
127.0.0.1  quiz-app.local
```

**Test** :
```bash
# Health check
curl http://quiz-app.local/health

# API
curl http://quiz-app.local/api/v1/quizzes
```

### 1.4 Frontend Flutter (développement)

```bash
# 1. Naviguer vers frontend
cd frontend

# 2. Installer dépendances
flutter pub get

# 3. Générer code (Freezed, JSON)
dart run build_runner build --delete-conflicting-outputs

# 4. Lancer sur émulateur/simulateur
flutter run

# Ou sur Chrome (web)
flutter run -d chrome
```

**Configuration API** :

Fichier `frontend/lib/core/config/api_config.dart` :

```dart
class ApiConfig {
  // Backend local
  static const String quizServiceUrl = 'http://localhost:8080/api/v1';
  
  // Backend Kubernetes
  // static const String quizServiceUrl = 'http://quiz-app.local/api/v1';
  
  // Android Emulator
  // static const String quizServiceUrl = 'http://10.0.2.2:8080/api/v1';
}
```

---

## 2. Utilisation de l'API

### 2.1 Endpoints disponibles

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/v1/quizzes` | Liste des quiz |
| GET | `/api/v1/quizzes/:id` | Détails d'un quiz |
| GET | `/api/v1/quizzes/:quiz_id/questions` | Questions d'un quiz |
| POST | `/api/v1/quizzes/:quiz_id/sessions` | Démarrer une session |
| POST | `/api/v1/sessions/:session_id/answers` | Soumettre une réponse |
| POST | `/api/v1/sessions/:session_id/finalize` | Finaliser une session |
| GET | `/api/v1/sessions/:session_id` | Récupérer une session |

### 2.2 Workflow complet (curl)

**1. Lister les quiz disponibles**

```bash
curl -X GET http://localhost:8080/api/v1/quizzes | jq

# Réponse :
[
  {
    "id": "00000000-0000-0000-0000-000000000001",
    "domain": "geography",
    "titre": "Géographie de France - Découverte",
    "description": "Quiz de découverte sur la géographie française",
    "niveau_difficulte": "facile",
    "scope": "france",
    "mode": "decouverte",
    "nb_questions": 10,
    "is_active": true,
    "created_at": "2024-01-15T10:30:00Z"
  }
]
```

**2. Récupérer les questions d'un quiz**

```bash
curl -X GET http://localhost:8080/api/v1/quizzes/00000000-0000-0000-0000-000000000001/questions | jq

# Réponse (extrait) :
[
  {
    "id": "00000000-0000-0000-0001-000000000001",
    "quiz_id": "00000000-0000-0000-0000-000000000001",
    "ordre": 1,
    "category": "fleuves",
    "subcategory": "hydrographie",
    "type_question": "qcm",
    "question_data": {
      "text": "Quel est le plus long fleuve de France ?"
    },
    "points": 10,
    "temps_limite_sec": 15,
    "hint": "Il traverse le centre de la France",
    "explanation": "La Loire est le plus long fleuve...",
    "reponses": [
      {
        "id": "xxxxx",
        "valeur": "La Loire",
        "ordre": 1
        // ⚠️ is_correct N'EST PAS exposé
      },
      {
        "id": "yyyyy",
        "valeur": "La Seine",
        "ordre": 2
      }
    ]
  }
]
```

**3. Démarrer une session**

```bash
curl -X POST http://localhost:8080/api/v1/quizzes/00000000-0000-0000-0000-000000000001/sessions \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "11111111-1111-1111-1111-111111111111"
  }' | jq

# Réponse :
{
  "id": "22222222-2222-2222-2222-222222222222",
  "user_id": "11111111-1111-1111-1111-111111111111",
  "quiz_id": "00000000-0000-0000-0000-000000000001",
  "score": 0,
  "score_max": 100,
  "pourcentage": null,
  "status": "en_cours",
  "date_debut": "2024-01-15T14:30:00Z",
  "date_fin": null
}
```

**4. Soumettre une réponse (QCM)**

```bash
# Stocker l'ID de session
SESSION_ID="22222222-2222-2222-2222-222222222222"

curl -X POST http://localhost:8080/api/v1/sessions/$SESSION_ID/answers \
  -H "Content-Type: application/json" \
  -d '{
    "question_id": "00000000-0000-0000-0001-000000000001",
    "reponse_id": "xxxxx",
    "temps_reponse_sec": 8
  }' | jq

# Réponse :
{
  "id": "33333333-3333-3333-3333-333333333333",
  "session_id": "22222222-2222-2222-2222-222222222222",
  "question_id": "00000000-0000-0000-0001-000000000001",
  "reponse_id": "xxxxx",
  "is_correct": true,
  "points_obtenus": 15,  // 10 pts base + 5 bonus vitesse
  "temps_reponse_sec": 8,
  "created_at": "2024-01-15T14:30:08Z"
}
```

**5. Soumettre une réponse (Saisie texte)**

```bash
curl -X POST http://localhost:8080/api/v1/sessions/$SESSION_ID/answers \
  -H "Content-Type: application/json" \
  -d '{
    "question_id": "00000000-0000-0000-0001-000000000003",
    "valeur_saisie": "seine",
    "temps_reponse_sec": 12
  }' | jq

# Réponse :
{
  "id": "44444444-4444-4444-4444-444444444444",
  "session_id": "22222222-2222-2222-2222-222222222222",
  "question_id": "00000000-0000-0000-0001-000000000003",
  "valeur_saisie": "seine",
  "is_correct": true,
  "points_obtenus": 10,
  "temps_reponse_sec": 12,
  "created_at": "2024-01-15T14:30:20Z"
}
```

**6. Finaliser la session**

```bash
curl -X POST http://localhost:8080/api/v1/sessions/$SESSION_ID/finalize | jq

# Réponse :
{
  "id": "22222222-2222-2222-2222-222222222222",
  "user_id": "11111111-1111-1111-1111-111111111111",
  "quiz_id": "00000000-0000-0000-0000-000000000001",
  "score": 85,
  "score_max": 100,
  "pourcentage": 85.0,
  "temps_total_sec": 245,
  "status": "termine",
  "date_debut": "2024-01-15T14:30:00Z",
  "date_fin": "2024-01-15T14:34:05Z"
}
```

**7. Récupérer une session**

```bash
curl -X GET http://localhost:8080/api/v1/sessions/$SESSION_ID | jq

# (même structure que ci-dessus)
```

---

## 3. Utilisation de l'application Flutter

### 3.1 Parcours utilisateur

**1. Écran d'accueil (Liste des quiz)**

```
┌─────────────────────────────────────┐
│  Quiz Disponibles              🔄   │
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │ 🌍 Géographie de France       │ │
│  │ Découverte sur la géo française│ │
│  │                                │ │
│  │ 🟢 facile  📝 10 questions    │ │
│  │ ⏱️ ~5 min   📖 Découverte     │ │
│  └───────────────────────────────┘ │
│                                     │
│  [Autres quiz...]                  │
│                                     │
└─────────────────────────────────────┘
```

**Actions** :
- Pull-to-refresh pour rafraîchir la liste
- Tap sur une carte → Démarrage du quiz

**2. Session de quiz (Question en cours)**

```
┌─────────────────────────────────────┐
│  Géographie de France          ❌   │
├─────────────────────────────────────┤
│ [████████░░░░░░░░] 8/10             │
├─────────────────────────────────────┤
│                                     │
│  Question 8 / 10       ⏱️ 12s       │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 📝 Qcm • 10 points              ││
│  │                                 ││
│  │ Combien de régions compte      ││
│  │ la France métropolitaine ?     ││
│  │                                 ││
│  │ ⭐ 10 points  ⏱️ 15s            ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ ○  13                           ││ ← Options
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ ●  12                           ││ ← Sélectionné
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ ○  18                           ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ ○  22                           ││
│  └─────────────────────────────────┘│
│                                     │
│  💡 Besoin d'un indice ?            │
│                                     │
│  ┌─────────────────────────────────┐│
│  │         VALIDER                 ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

**Actions** :
- Tap sur une option → Sélection
- Tap "VALIDER" → Soumettre réponse
- Tap "💡" → Afficher indice

**3. Feedback après réponse**

```
┌─────────────────────────────────────┐
│  Géographie de France          ❌   │
├─────────────────────────────────────┤
│ [████████░░░░░░░░] 8/10             │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────────┐│
│  │        ❌  Incorrect            ││
│  │                                 ││
│  │         +0 points               ││
│  │                                 ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ ℹ️  Explication                 ││
│  │                                 ││
│  │ La France métropolitaine compte││
│  │ 13 régions depuis 2016          ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │ Score: 75   Questions: 8 / 10  ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │    ➡️ Question suivante         ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

**Actions** :
- Tap "Question suivante" → Prochaine question
- Si dernière question → "🏆 Voir les résultats"

**4. Page de résultats**

```
┌─────────────────────────────────────┐
│  Résultats                          │
├─────────────────────────────────────┤
│                                     │
│            🎉                        │
│                                     │
│       Très bien !                   │
│                                     │
│  ┌─────────────────────────────────┐│
│  │       Score Final               ││
│  │                                 ││
│  │          75                     ││
│  │       sur 100 points            ││
│  │                                 ││
│  │         75.0%                   ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │      Statistiques               ││
│  │                                 ││
│  │  📝 Questions          10       ││
│  │  ────────────────────────────  ││
│  │  ✅ Bonnes réponses    7       ││
│  │  ────────────────────────────  ││
│  │  ❌ Mauvaises réponses 3       ││
│  │  ────────────────────────────  ││
│  │  ⏱️ Temps total       4 min    ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  🎉 Félicitations !             ││
│  │  Vous avez réussi ce quiz !    ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │   Retour à l'accueil            ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │   Recommencer                   ││
│  └─────────────────────────────────┘│
│                                     │
└─────────────────────────────────────┘
```

### 3.2 Gestion du timer

**Questions avec temps limite** :
- Countdown affiché en haut à droite
- Si temps écoulé → Soumission automatique avec `reponse_id = null`
- Backend retourne `is_correct = false` et `points_obtenus = 0`

**Questions sans temps limite** :
- Timer elapsed affiché (00:12, 01:05, etc.)
- Pas de soumission auto

---

## 4. Workflows de développement

### 4.1 Ajouter un nouveau domaine de quiz

**Exemple : Code de la Route**

**Étape 1 : Créer le plugin backend**

```rust
// backend/quiz_core_service/src/plugins/code_route/code_route_plugin.rs

use async_trait::async_trait;
use shared::AppError;
use sqlx::PgPool;
use crate::plugins::{QuizPlugin, ValidationResult};

pub struct CodeRoutePlugin;

#[async_trait]
impl QuizPlugin for CodeRoutePlugin {
    fn domain_name(&self) -> &str {
        "code_route"
    }
    
    fn display_name(&self) -> &str {
        "Code de la Route"
    }
    
    async fn validate_answer(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        match question.type_question.as_str() {
            "qcm" => self.validate_qcm(pool, question, answer).await,
            "vrai_faux" => self.validate_vrai_faux(pool, question, answer).await,
            // Logique spécifique code route
            _ => Err(AppError::BadRequest("Type non supporté".to_string()))
        }
    }
    
    fn calculate_score(
        &self,
        base_points: i32,
        validation: &ValidationResult,
        time_spent: i32,
        time_limit: Option<i32>,
        streak_count: i32,
    ) -> i32 {
        // Scoring spécifique code route (plus strict ?)
        if !validation.is_correct {
            return 0;
        }
        // ...
    }
}
```

**Étape 2 : Enregistrer le plugin**

```rust
// backend/quiz_core_service/src/main.rs

let mut plugin_registry = PluginRegistry::new();
plugin_registry.register(Arc::new(GeographyPlugin));
plugin_registry.register(Arc::new(CodeRoutePlugin)); // ✅ NOUVEAU
```

**Étape 3 : Créer le domaine en DB**

```sql
-- Migration : backend/quiz_core_service/migrations/xxxxx_add_code_route_domain.sql

INSERT INTO domains (name, display_name, description, config)
VALUES (
    'code_route',
    'Code de la Route',
    'Quiz sur le code de la route français',
    '{"icon": "🚗", "color": "#FF5722"}'::jsonb
);
```

**Étape 4 : Créer des quiz**

```sql
INSERT INTO quizzes (domain, titre, scope, mode, niveau_difficulte, nb_questions)
VALUES (
    'code_route',
    'Panneaux de signalisation',
    'france',
    'entrainement',
    'moyen',
    20
);
```

**Étape 5 : Créer des questions**

```sql
INSERT INTO questions (
    quiz_id, ordre, type_question, question_data,
    category, subcategory, points, temps_limite_sec
)
VALUES (
    '<quiz_id>',
    1,
    'qcm',
    '{"text": "Que signifie ce panneau ?", "image": "https://..."}'::jsonb,
    'panneaux',
    'interdiction',
    10,
    15
);

INSERT INTO reponses (question_id, valeur, is_correct, ordre)
VALUES
    ('<question_id>', 'Interdiction de tourner à gauche', true, 1),
    ('<question_id>', 'Sens interdit', false, 2),
    ('<question_id>', 'Arrêt obligatoire', false, 3);
```

### 4.2 Ajouter un nouveau type de question

**Exemple : Questions d'ordre (classer des éléments)**

**Étape 1 : Modifier le plugin**

```rust
// Dans GeographyPlugin::validate_answer()

match question.type_question.as_str() {
    "qcm" => self.validate_qcm(pool, question, answer).await,
    "vrai_faux" => self.validate_vrai_faux(pool, question, answer).await,
    "saisie_texte" => self.validate_saisie_texte_geo(pool, question, answer).await,
    "ordre" => self.validate_ordre(pool, question, answer).await, // ✅ NOUVEAU
    _ => Err(AppError::BadRequest("Type non supporté".to_string()))
}

// Implémenter la validation
async fn validate_ordre(
    &self,
    pool: &PgPool,
    question: &Question,
    answer: &SubmitAnswerRequest,
) -> Result<ValidationResult, AppError> {
    // valeur_saisie contient l'ordre choisi : "1,3,2,4"
    let user_order = answer.valeur_saisie.as_ref()...;
    
    // Récupérer l'ordre correct depuis DB
    let correct_order = sqlx::query_scalar(...).fetch_one(pool).await?;
    
    // Comparer
    let is_correct = user_order == correct_order;
    
    // Ou scoring partiel selon nombre d'éléments bien placés
    let partial_score = calculate_partial(...);
    
    Ok(ValidationResult::partial(partial_score, "..."))
}
```

**Étape 2 : Mettre à jour le frontend**

```dart
// frontend/lib/features/quiz/presentation/widgets/question_card.dart

// Ajouter le rendu pour type "ordre"
if (question.isOrdre) {
  return OrderQuestionWidget(
    items: question.orderItems,
    onReorder: (newOrder) => ...,
  );
}
```

### 4.3 Lancer les tests

**Backend** :

```bash
cd backend/quiz_core_service

# Tests unitaires
cargo test --lib

# Tests d'intégration (nécessite PostgreSQL)
cargo test --test '*'

# Avec coverage
cargo install cargo-llvm-cov
cargo llvm-cov --html --output-dir coverage-report
# Ouvrir coverage-report/index.html
```

**Frontend** :

```bash
cd frontend

# Tests unitaires
flutter test

# Tests avec coverage
flutter test --coverage
# Ouvrir coverage/lcov-report/index.html
```

### 4.4 Formater le code

**Backend** :

```bash
cd backend/quiz_core_service
cargo fmt
cargo clippy -- -D warnings
```

**Frontend** :

```bash
cd frontend
dart format .
flutter analyze
```

---

## 5. Déploiement

### 5.1 Build image Docker (backend)

```bash
# Depuis la racine
cd backend
docker build -t quiz-backend:v1.0.0 -f ../docker/backend.Dockerfile .

# Tag pour registry
docker tag quiz-backend:v1.0.0 <registry>/quiz-backend:v1.0.0

# Push
docker push <registry>/quiz-backend:v1.0.0
```

### 5.2 Déploiement Kubernetes (production)

**Mettre à jour l'image** :

```bash
# Modifier k8s/kind/manifests/09-backend-deployment.yaml
# Remplacer :
#   image: quiz-backend:local
# Par :
#   image: <registry>/quiz-backend:v1.0.0

kubectl apply -f k8s/kind/manifests/09-backend-deployment.yaml

# Vérifier le rollout
kubectl rollout status deployment/quiz-backend -n quiz-app
```

**Ou via commande kubectl** :

```bash
kubectl set image deployment/quiz-backend \
  quiz-backend=<registry>/quiz-backend:v1.0.0 \
  -n quiz-app

kubectl rollout status deployment/quiz-backend -n quiz-app
```

### 5.3 Activation TLS/HTTPS (production)

**Installer cert-manager** :

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

**Créer un ClusterIssuer** :

```yaml
# cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
      - http01:
          ingress:
            class: nginx
```

**Mettre à jour l'Ingress** :

```yaml
# k8s/kind/manifests/10-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: quiz-app-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"  # ✅ Activer
spec:
  tls:  # ✅ Ajouter section TLS
    - hosts:
        - quiz-app.yourdomain.com
      secretName: quiz-app-tls
  rules:
    - host: quiz-app.yourdomain.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: quiz-backend
                port:
                  number: 8080
```

### 5.4 Monitoring (optionnel)

**Installer Prometheus + Grafana** :

```bash
# Ajouter Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Installer kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace
```

**Accéder à Grafana** :

```bash
# Port-forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# User: admin
# Password:
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode
```

---

## 6. Résolution de problèmes

### 6.1 Backend ne démarre pas

**Symptôme** : `Error: could not connect to server: Connection refused`

**Solution** :
```bash
# Vérifier que PostgreSQL tourne
docker ps | grep postgres
# ou
kubectl get pods -n quiz-app | grep postgres

# Vérifier la variable DATABASE_URL
echo $DATABASE_URL

# Tester la connexion
psql postgresql://quiz_user:quiz@localhost:5432/quiz_db
```

### 6.2 Frontend ne se connecte pas à l'API

**Symptôme** : `DioException: Connection refused`

**Solutions** :

1. **Backend local** : Vérifier que le backend tourne sur `localhost:8080`
   ```bash
   curl http://localhost:8080/health
   ```

2. **Android Emulator** : Utiliser `10.0.2.2` au lieu de `localhost`
   ```dart
   // api_config.dart
   static const String quizServiceUrl = 'http://10.0.2.2:8080/api/v1';
   ```

3. **Kubernetes** : Vérifier `/etc/hosts` et que l'Ingress fonctionne
   ```bash
   curl http://quiz-app.local/health
   ```

### 6.3 Erreur 404 sur les routes

**Symptôme** : `404 Not Found` sur `/api/v1/quizzes`

**Solution** :
```bash
# Vérifier les routes enregistrées
# Ajouter du logging dans routes.rs

# Vérifier l'Ingress
kubectl describe ingress quiz-app-ingress -n quiz-app

# Vérifier le Service
kubectl get svc quiz-backend -n quiz-app
kubectl describe svc quiz-backend -n quiz-app
```

### 6.4 Migrations SQL échouent

**Symptôme** : `error: no migration found`

**Solution** :
```bash
# Installer sqlx-cli
cargo install sqlx-cli --no-default-features --features postgres

# Vérifier les migrations
cd backend/quiz_core_service
ls migrations/

# Lancer les migrations
sqlx migrate run

# En cas d'erreur, vérifier DATABASE_URL
export DATABASE_URL=postgresql://quiz_user:quiz@localhost:5432/quiz_db
```

### 6.5 Pods Kubernetes ne démarrent pas

**Symptôme** : `CrashLoopBackOff` ou `ImagePullBackOff`

**Solutions** :

1. **ImagePullBackOff** :
   ```bash
   # Vérifier que l'image existe
   docker images | grep quiz-backend
   
   # Si utilise kind, charger l'image
   kind load docker-image quiz-backend:local --name quiz-cluster
   ```

2. **CrashLoopBackOff** :
   ```bash
   # Voir les logs
   kubectl logs -f deployment/quiz-backend -n quiz-app
   
   # Voir les events
   kubectl describe pod <pod-name> -n quiz-app
   
   # Vérifier les secrets
   kubectl get secret quiz-secrets -n quiz-app -o yaml
   ```

### 6.6 Questions ne s'affichent pas dans le frontend

**Symptôme** : Liste vide ou erreur de parsing

**Solutions** :

1. Vérifier la réponse de l'API :
   ```bash
   curl http://localhost:8080/api/v1/quizzes/<id>/questions | jq
   ```

2. Vérifier le mapping Model → Entity :
   ```dart
   // Mettre des logs dans question_model_mapper.dart
   print('Mapping question: ${model.id}');
   ```

3. Vérifier que `reponses` est bien inclus :
   ```sql
   -- Dans question_repo.rs : find_by_quiz_id_with_reponses()
   SELECT * FROM questions WHERE quiz_id = $1;
   -- puis
   SELECT * FROM reponses WHERE question_id = $1;
   ```

---

## Annexes

### A. Commandes utiles

**Docker** :
```bash
# Voir les containers
docker ps -a

# Logs d'un container
docker logs -f <container_name>

# Shell dans un container
docker exec -it <container_name> sh

# Nettoyer
docker system prune -a
```

**Kubernetes** :
```bash
# Voir tout
kubectl get all -n quiz-app

# Logs
kubectl logs -f deployment/quiz-backend -n quiz-app
kubectl logs -f statefulset/postgres -n quiz-app

# Shell dans un pod
kubectl exec -it deployment/quiz-backend -n quiz-app -- sh
kubectl exec -it statefulset/postgres -n quiz-app -- psql -U quiz_user quiz_db

# Port-forward
kubectl port-forward svc/quiz-backend 8080:8080 -n quiz-app

# Supprimer tout
kubectl delete namespace quiz-app
```

**PostgreSQL** :
```bash
# Se connecter
psql postgresql://quiz_user:quiz@localhost:5432/quiz_db

# Commandes utiles
\dt           # Lister tables
\d quizzes    # Décrire table
SELECT * FROM quizzes;
SELECT * FROM questions WHERE quiz_id = '...';
```

### B. Variables d'environnement

**Backend** :
```bash
DATABASE_URL=postgresql://quiz_user:quiz@localhost:5432/quiz_db
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
RUST_LOG=info,quiz_service=debug
JWT_SECRET=dev-secret-key
```

**Frontend** :
```dart
// Pas de variables d'environnement côté Flutter
// Configuration dans lib/core/config/api_config.dart
```

### C. Structure des données JSON

**Quiz** :
```json
{
  "id": "uuid",
  "domain": "geography",
  "titre": "string",
  "scope": "france",
  "mode": "decouverte",
  "niveau_difficulte": "facile",
  "nb_questions": 10,
  "is_active": true
}
```

**Question (avec réponses)** :
```json
{
  "id": "uuid",
  "quiz_id": "uuid",
  "ordre": 1,
  "category": "fleuves",
  "type_question": "qcm",
  "question_data": {"text": "..."},
  "points": 10,
  "temps_limite_sec": 15,
  "reponses": [
    {
      "id": "uuid",
      "valeur": "La Loire",
      "ordre": 1
    }
  ]
}
```

**Session** :
```json
{
  "id": "uuid",
  "user_id": "uuid",
  "quiz_id": "uuid",
  "score": 75,
  "score_max": 100,
  "pourcentage": 75.0,
  "status": "termine"
}
```

**Réponse utilisateur** :
```json
{
  "id": "uuid",
  "session_id": "uuid",
  "question_id": "uuid",
  "reponse_id": "uuid",
  "is_correct": true,
  "points_obtenus": 15,
  "temps_reponse_sec": 8
}
```

---

## Conclusion

Vous disposez maintenant de tous les outils pour :

✅ Installer et lancer l'application localement  
✅ Utiliser l'API REST pour créer des sessions de quiz  
✅ Développer de nouveaux domaines et types de questions  
✅ Déployer en production sur Kubernetes  
✅ Résoudre les problèmes courants

**Support** :
- Issues GitHub : <repo-url>/issues
- Documentation technique : DOCUMENTATION_TECHNIQUE.md

Bon développement ! 🚀