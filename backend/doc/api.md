# 📡 API Documentation

Documentation complète de l'API REST du système de quiz.

## Base URL
```
http://localhost:8080/api/v1
```

## Format des Réponses

Toutes les réponses sont au format JSON avec encodage UTF-8.

### Succès
```json
{
  "data": { ... }
}
```

### Erreurs
```json
{
  "error": "Message d'erreur descriptif"
}
```

## Codes HTTP

| Code | Description |
|------|-------------|
| 200 | Succès |
| 201 | Créé |
| 400 | Requête invalide |
| 404 | Ressource non trouvée |
| 500 | Erreur serveur |

---

## 🏥 Health Check

### GET /health

Vérifier l'état du serveur.

**Requête**
```http
GET http://localhost:8080/health
```

**Réponse 200**
```json
{
  "status": "healthy",
  "service": "quiz_core_service",
  "version": "0.1.0"
}
```

---

## 📚 Quiz Endpoints

### GET /api/v1/quizzes

Récupérer la liste de tous les quiz actifs.

**Requête**
```http
GET /api/v1/quizzes
```

**Query Parameters**

| Paramètre | Type | Description | Exemple |
|-----------|------|-------------|---------|
| `domain` | string | Filtrer par domaine | `geography` |
| `niveau_difficulte` | string | Filtrer par difficulté | `facile`, `moyen`, `difficile` |
| `scope` | string | Filtrer par portée | `france`, `europe`, `monde` |

**Exemple avec filtres**
```http
GET /api/v1/quizzes?domain=geography&niveau_difficulte=facile
```

**Réponse 200**
```json
[
  {
    "id": "00000000-0000-0000-0000-000000000001",
    "domain": "geography",
    "titre": "Géographie de France - Découverte",
    "description": "Quiz de découverte sur la géographie française",
    "niveau_difficulte": "facile",
    "version_app": "1.0.0",
    "scope": "france",
    "mode": "decouverte",
    "nb_questions": 10,
    "temps_limite_sec": null,
    "score_minimum_success": 50,
    "is_active": true,
    "is_public": true,
    "total_attempts": 0,
    "average_score": null,
    "created_at": "2025-10-30T20:28:44.142935Z",
    "updated_at": "2025-10-30T20:28:44.142935Z"
  }
]
```

---

### GET /api/v1/quizzes/:id

Récupérer les détails d'un quiz spécifique.

**Requête**
```http
GET /api/v1/quizzes/00000000-0000-0000-0000-000000000001
```

**Réponse 200**
```json
{
  "id": "00000000-0000-0000-0000-000000000001",
  "domain": "geography",
  "titre": "Géographie de France - Découverte",
  "description": "Quiz de découverte sur la géographie française",
  "niveau_difficulte": "facile",
  "scope": "france",
  "mode": "decouverte",
  "nb_questions": 10,
  "is_active": true
}
```

**Réponse 404**
```json
{
  "error": "Quiz with id <uuid> not found"
}
```

---

### GET /api/v1/quizzes/:id/questions

Récupérer toutes les questions d'un quiz avec leurs réponses.

**Requête**
```http
GET /api/v1/quizzes/00000000-0000-0000-0000-000000000001/questions
```

**Réponse 200**
```json
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
    "media_url": null,
    "target_id": null,
    "points": 10,
    "temps_limite_sec": 15,
    "hint": "Il traverse le centre de la France",
    "explanation": "La Loire est le plus long fleuve de France avec 1 006 km",
    "reponses": [
      {
        "id": "5e8ca02d-2547-438e-9900-8049b5fceb79",
        "valeur": "La Loire",
        "ordre": 1
      },
      {
        "id": "1515d4d6-410e-4380-9e6c-c79b88c92e5f",
        "valeur": "La Seine",
        "ordre": 2
      },
      {
        "id": "ad1d8d79-c06f-4397-b5af-95c62fbee316",
        "valeur": "Le Rhône",
        "ordre": 3
      },
      {
        "id": "919a99b7-9bc5-44a7-b09d-dd22b170803c",
        "valeur": "La Garonne",
        "ordre": 4
      }
    ]
  },
  {
    "id": "00000000-0000-0000-0001-000000000002",
    "ordre": 2,
    "type_question": "vrai_faux",
    "question_data": {
      "text": "Le Rhône prend sa source en Suisse"
    },
    "reponses": [
      {
        "id": "fda0b8ee-7c8a-411b-81df-2a68dceccbd5",
        "valeur": "Vrai",
        "ordre": 1
      },
      {
        "id": "4730db82-0c4e-4cbd-b8ce-b7a798efbd5d",
        "valeur": "Faux",
        "ordre": 2
      }
    ]
  },
  {
    "id": "00000000-0000-0000-0001-000000000003",
    "ordre": 3,
    "type_question": "saisie_texte",
    "question_data": {
      "text": "Quel fleuve traverse Paris ?"
    },
    "reponses": [
      {
        "id": "5a846f2d-a368-4083-8f4d-5a523a62b3d8",
        "valeur": "seine",
        "ordre": 0
      },
      {
        "id": "5a9a1c20-03ba-45fa-a36f-b8436c772ff8",
        "valeur": "la seine",
        "ordre": 0
      }
    ]
  }
]
```

**Notes importantes :**
- ⚠️ `is_correct` n'est JAMAIS exposé pour les QCM/Vrai-Faux (sécurité)
- Les réponses pour `saisie_texte` montrent les variantes acceptées (normalisées en minuscules)

---

## 🎮 Session Endpoints

### POST /api/v1/quizzes/:id/sessions

Démarrer une nouvelle session de quiz.

**Requête**
```http
POST /api/v1/quizzes/00000000-0000-0000-0000-000000000001/sessions
Content-Type: application/json
```

**Body**
```json
{
  "user_id": "11111111-1111-1111-1111-111111111111"
}
```

**Réponse 201**
```json
{
  "id": "5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f",
  "user_id": "11111111-1111-1111-1111-111111111111",
  "quiz_id": "00000000-0000-0000-0000-000000000001",
  "score": 0,
  "score_max": 100,
  "pourcentage": 0.0,
  "temps_total_sec": null,
  "date_debut": "2025-10-31T23:17:29.123456Z",
  "date_fin": null,
  "status": "en_cours",
  "reponses_detaillees": [],
  "metadata": {},
  "created_at": "2025-10-31T23:17:29.123456Z"
}
```

**Réponse 400**
```json
{
  "error": "Ce quiz n'est plus actif"
}
```

**Réponse 404**
```json
{
  "error": "Quiz with id <uuid> not found"
}
```

---

### GET /api/v1/sessions/:id

Récupérer les détails d'une session.

**Requête**
```http
GET /api/v1/sessions/5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f
```

**Réponse 200**
```json
{
  "id": "5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f",
  "user_id": "11111111-1111-1111-1111-111111111111",
  "quiz_id": "00000000-0000-0000-0000-000000000001",
  "score": 29,
  "score_max": 100,
  "pourcentage": 29.0,
  "status": "en_cours",
  "date_debut": "2025-10-31T23:17:29.123456Z",
  "date_fin": null
}
```

---

### POST /api/v1/sessions/:id/answers

Soumettre une réponse à une question.

**Important :** On ne peut répondre qu'**une seule fois** à chaque question par session.

#### Type QCM / Vrai-Faux

**Requête**
```http
POST /api/v1/sessions/5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f/answers
Content-Type: application/json
```

**Body**
```json
{
  "question_id": "00000000-0000-0000-0001-000000000001",
  "reponse_id": "5e8ca02d-2547-438e-9900-8049b5fceb79",
  "temps_reponse_sec": 5
}
```

**Réponse 200 (Bonne réponse avec bonus vitesse)**
```json
{
  "id": "de9acb33-79ad-423a-8f28-dc6b92bb2b92",
  "session_id": "5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f",
  "question_id": "00000000-0000-0000-0001-000000000001",
  "reponse_id": "5e8ca02d-2547-438e-9900-8049b5fceb79",
  "valeur_saisie": null,
  "is_correct": true,
  "points_obtenus": 15,
  "temps_reponse_sec": 5,
  "metadata": {},
  "created_at": "2025-10-31T23:18:02.318174Z"
}
```

**Explication du score :**
- Points de base : 10
- Bonus vitesse : +50% (répondu en 5 sec sur 15 sec = 33%, donc très rapide)
- Score final : 15 points

---

#### Type Saisie Texte

**Requête**
```http
POST /api/v1/sessions/5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f/answers
Content-Type: application/json
```

**Body**
```json
{
  "question_id": "00000000-0000-0000-0001-000000000003",
  "valeur_saisie": "Seine",
  "temps_reponse_sec": 8
}
```

**Réponse 200**
```json
{
  "id": "abc123...",
  "session_id": "5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f",
  "question_id": "00000000-0000-0000-0001-000000000003",
  "reponse_id": null,
  "valeur_saisie": "Seine",
  "is_correct": true,
  "points_obtenus": 13,
  "temps_reponse_sec": 8
}
```

**Notes :**
- La saisie est normalisée (majuscules/minuscules ignorées)
- Les variantes acceptées : "seine", "Seine", "la seine", "La Seine"

---

#### Réponse Incorrecte

**Réponse 200**
```json
{
  "id": "def456...",
  "is_correct": false,
  "points_obtenus": 0,
  "temps_reponse_sec": 10
}
```

---

#### Erreurs Possibles

**Réponse déjà donnée (400)**
```json
{
  "error": "You have already answered this question in this session"
}
```

**Session non active (400)**
```json
{
  "error": "Session not found or already completed"
}
```

**Question n'appartient pas au quiz (400)**
```json
{
  "error": "Question does not belong to this quiz"
}
```

---

### POST /api/v1/sessions/:id/finalize

Finaliser une session de quiz.

**Requête**
```http
POST /api/v1/sessions/5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f/finalize
```

**Pas de body**

**Réponse 200**
```json
{
  "id": "5095cdf3-5e89-4ea0-bb26-1fcbfb75f82f",
  "user_id": "11111111-1111-1111-1111-111111111111",
  "quiz_id": "00000000-0000-0000-0000-000000000001",
  "score": 44,
  "score_max": 100,
  "pourcentage": 44.0,
  "temps_total_sec": 120,
  "date_debut": "2025-10-31T23:17:29.123456Z",
  "date_fin": "2025-10-31T23:19:29.123456Z",
  "status": "termine",
  "reponses_detaillees": [],
  "metadata": {},
  "created_at": "2025-10-31T23:17:29.123456Z"
}
```

**Réponse 400**
```json
{
  "error": "Session not found or already finalized"
}
```

---

## 🎯 Système de Scoring

### Calcul des Points

#### 1. Points de Base
Définis dans la question (généralement 10 points).

#### 2. Bonus Vitesse

| Temps utilisé | Bonus | Exemple (base 10) |
|---------------|-------|-------------------|
| < 30% du temps limite | +50% | 15 points |
| < 50% du temps limite | +25% | 12.5 points |
| 50-90% du temps limite | 0% | 10 points |
| > 90% du temps limite | -25% | 7.5 points |

#### 3. Bonus Streak

Bonnes réponses consécutives :

| Streak | Bonus | Exemple (base 10) |
|--------|-------|-------------------|
| 3 | +10% | +1 point |
| 4 | +20% | +2 points |
| 5 | +30% | +3 points |
| 6+ | +40-50% (max) | +4-5 points |

#### 4. Formule Finale
```
Score = (Points_base × Bonus_vitesse) + (Points_base × Bonus_streak)
```

### Exemple Complet

**Question :** 10 points, temps limite 15 secondes

**Scénario 1 : Réponse rapide + Streak**
- Temps : 4 secondes (26% du temps)
- Streak : 3 bonnes réponses d'affilée
- Calcul : (10 × 1.5) + (10 × 0.1) = 15 + 1 = **16 points**

**Scénario 2 : Réponse normale**
- Temps : 10 secondes (66% du temps)
- Pas de streak
- Calcul : 10 × 1.0 = **10 points**

**Scénario 3 : Réponse lente**
- Temps : 14 secondes (93% du temps)
- Pas de streak
- Calcul : 10 × 0.75 = **7.5 points** (arrondi à 8)

---

## 📊 Types de Questions

### QCM (Choix Multiple)
```json
{
  "type_question": "qcm",
  "question_data": {
    "text": "Quelle est la capitale de la France ?"
  },
  "reponses": [
    {"id": "uuid1", "valeur": "Paris", "ordre": 1},
    {"id": "uuid2", "valeur": "Lyon", "ordre": 2},
    {"id": "uuid3", "valeur": "Marseille", "ordre": 3}
  ]
}
```

**Pour répondre :**
```json
{
  "question_id": "uuid",
  "reponse_id": "uuid1",
  "temps_reponse_sec": 5
}
```

---

### Vrai/Faux
```json
{
  "type_question": "vrai_faux",
  "question_data": {
    "text": "Le Rhône prend sa source en Suisse"
  },
  "reponses": [
    {"id": "uuid1", "valeur": "Vrai", "ordre": 1},
    {"id": "uuid2", "valeur": "Faux", "ordre": 2}
  ]
}
```

**Pour répondre :**
```json
{
  "question_id": "uuid",
  "reponse_id": "uuid1",
  "temps_reponse_sec": 3
}
```

---

### Saisie Texte
```json
{
  "type_question": "saisie_texte",
  "question_data": {
    "text": "Quel fleuve traverse Paris ?"
  },
  "reponses": [
    {"id": "uuid1", "valeur": "seine", "ordre": 0},
    {"id": "uuid2", "valeur": "la seine", "ordre": 0}
  ]
}
```

**Pour répondre :**
```json
{
  "question_id": "uuid",
  "valeur_saisie": "Seine",
  "temps_reponse_sec": 8
}
```

**Notes :**
- La casse est ignorée
- Les variantes sont acceptées

---

## 🔐 Sécurité

### 1. Validation Serveur
Toute validation se fait côté serveur via les plugins.

### 2. Protection des Réponses
`is_correct` n'est **JAMAIS** exposé dans l'API pour les QCM/Vrai-Faux.

### 3. Une Réponse par Question
Contrainte DB : `UNIQUE(session_id, question_id)`

### 4. Session Active
On ne peut répondre qu'aux sessions avec `status = "en_cours"`.

---

## 📝 Exemples Complets

### Flow Complet d'un Quiz
```bash
# 1. Récupérer les quiz disponibles
GET /api/v1/quizzes

# 2. Récupérer les questions du quiz choisi
GET /api/v1/quizzes/00000000-0000-0000-0000-000000000001/questions

# 3. Démarrer une session
POST /api/v1/quizzes/00000000-0000-0000-0000-000000000001/sessions
Body: {"user_id": "11111111-1111-1111-1111-111111111111"}

# 4. Répondre aux questions (répéter pour chaque question)
POST /api/v1/sessions/{session_id}/answers
Body: {"question_id": "...", "reponse_id": "...", "temps_reponse_sec": 5}

# 5. Finaliser la session
POST /api/v1/sessions/{session_id}/finalize

# 6. Récupérer les résultats
GET /api/v1/sessions/{session_id}
```

---

## 🛠️ Outils de Test

### cURL
```bash
# Health check
curl http://localhost:8080/health

# Liste des quiz
curl http://localhost:8080/api/v1/quizzes

# Démarrer session
curl -X POST http://localhost:8080/api/v1/quizzes/00000000-0000-0000-0000-000000000001/sessions \
  -H "Content-Type: application/json" \
  -d '{"user_id":"11111111-1111-1111-1111-111111111111"}'
```

### Postman

Collection disponible : `postman_collection.json`

### HTTPie
```bash
# Démarrer session
http POST localhost:8080/api/v1/quizzes/00000000-0000-0000-0000-000000000001/sessions \
  user_id="11111111-1111-1111-1111-111111111111"
```

---

## 📈 Rate Limiting

Actuellement non implémenté. Prévu pour V1.

---

## 🔄 Versioning

API versionnée via URL : `/api/v1/...`

Changements breaking → nouvelle version : `/api/v2/...`