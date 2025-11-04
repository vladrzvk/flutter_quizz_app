# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

---

## [Non publié]

### À venir
- Authentification JWT
- Plus de questions géographiques
- Frontend Flutter
- Leaderboard
- Badges et achievements

---

## [0.1.0] - 2025-10-31

### 🎉 Version Initiale

#### Ajouté

##### Architecture
- ✅ Clean Architecture avec séparation des couches (Models, DTOs, Services, Repositories, Handlers)
- ✅ Système de plugins extensible pour supporter multiple domaines
- ✅ PluginRegistry pour enregistrer et gérer les plugins
- ✅ Trait `QuizPlugin` générique pour tous les domaines

##### Domaines
- ✅ **GeographyPlugin** - Premier plugin fonctionnel
    - Types de questions : QCM, Vrai/Faux, Saisie texte
    - Validation intelligente avec normalisation texte
    - Calcul de score avec bonus
    - Catégorisation : fleuves, reliefs, pays/régions

##### Base de Données
- ✅ PostgreSQL 15+ avec migrations SQLx
- ✅ Tables : `domains`, `quizzes`, `questions`, `reponses`, `sessions_quiz`, `reponses_utilisateur`
- ✅ Support des catégories et sous-catégories
- ✅ Contraintes d'intégrité (UNIQUE, CHECK, FK)
- ✅ Triggers automatiques (updated_at, pourcentage)
- ✅ Index pour performance
- ✅ Seed de données : 10 questions géographiques

##### API REST
- ✅ `GET /health` - Health check
- ✅ `GET /api/v1/quizzes` - Liste des quiz
- ✅ `GET /api/v1/quizzes/:id` - Détails quiz
- ✅ `GET /api/v1/quizzes/:id/questions` - Questions avec réponses
- ✅ `POST /api/v1/quizzes/:id/sessions` - Démarrer session
- ✅ `GET /api/v1/sessions/:id` - Détails session
- ✅ `POST /api/v1/sessions/:id/answers` - Soumettre réponse
- ✅ `POST /api/v1/sessions/:id/finalize` - Finaliser session

##### Fonctionnalités Quiz
- ✅ Types de questions : QCM, Vrai/Faux, Saisie texte
- ✅ Catégorisation des questions (category + subcategory)
- ✅ Temps limite par question
- ✅ Points personnalisables par question
- ✅ Hints et explications

##### Système de Scoring
- ✅ Points de base par question
- ✅ **Bonus vitesse** (jusqu'à +50% si très rapide, -25% si lent)
- ✅ **Bonus streak** (jusqu'à +50% pour séries de bonnes réponses)
- ✅ Calcul automatique du pourcentage
- ✅ Badges de vitesse personnalisés par plugin

##### Validation
- ✅ Validation côté serveur via plugins
- ✅ Normalisation saisie texte (majuscules/minuscules)
- ✅ Support des variantes de réponses
- ✅ Protection : `is_correct` jamais exposé pour QCM
- ✅ Contrainte : une seule réponse par question par session

##### Docker
- ✅ Docker Compose pour PostgreSQL et Redis
- ✅ Configuration environnement via `.env`
- ✅ Scripts de seed automatisés

##### Documentation
- ✅ README.md - Vue d'ensemble
- ✅ ARCHITECTURE.md - Architecture détaillée
- ✅ API.md - Documentation API complète
- ✅ SETUP.md - Guide d'installation
- ✅ PLUGIN_GUIDE.md - Créer un plugin
- ✅ DATABASE.md - Schéma et requêtes
- ✅ DEVELOPMENT.md - Workflow développeur

##### Tests
- ✅ Structure de tests (unit + integration)
- ✅ Exemples de tests pour services et plugins

##### DevOps
- ✅ Migrations SQLx
- ✅ Logging avec tracing
- ✅ Gestion d'erreurs avec AppError
- ✅ CORS configuré

#### Technologies

- **Rust** 1.75+
- **Axum** - Framework web
- **SQLx** - ORM async PostgreSQL
- **PostgreSQL** 15+ - Base de données
- **Docker** - Containerisation
- **Serde** - Sérialisation JSON
- **Tokio** - Runtime async
- **Tracing** - Logging structuré

---

## Types de Changements

- `Added` - Nouvelles fonctionnalités
- `Changed` - Modifications de fonctionnalités existantes
- `Deprecated` - Fonctionnalités bientôt supprimées
- `Removed` - Fonctionnalités supprimées
- `Fixed` - Corrections de bugs
- `Security` - Corrections de sécurité

---

## Liens

- [Documentation](docs/)
- [Issues](https://github.com/votre-repo/quiz-app/issues)
- [Discussions](https://github.com/votre-repo/quiz-app/discussions)
```

---

## 📱 ÉTAPE 2 : Frontend Flutter - Plan d'Action

### Architecture Proposée
```
frontend/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── api/
│   │   │   └── quiz_api_client.dart
│   │   ├── models/
│   │   │   ├── quiz.dart
│   │   │   ├── question.dart
│   │   │   ├── session.dart
│   │   │   └── reponse.dart
│   │   ├── providers/
│   │   │   ├── quiz_provider.dart
│   │   │   └── session_provider.dart
│   │   └── utils/
│   │       └── constants.dart
│   ├── features/
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   ├── quiz/
│   │   │   ├── quiz_list_screen.dart
│   │   │   ├── quiz_detail_screen.dart
│   │   │   └── widgets/
│   │   ├── play/
│   │   │   ├── play_screen.dart
│   │   │   ├── question_widget.dart
│   │   │   └── result_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   └── shared/
│       └── widgets/
│           ├── loading_widget.dart
│           └── error_widget.dart
└── pubspec.yaml